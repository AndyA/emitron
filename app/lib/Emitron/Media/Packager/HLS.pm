package Emitron::Media::Packager::HLS;

use Moose;

use Carp qw( croak );
use Emitron::Logger;
use Emitron::Media::Globals;
use Emitron::Media::Helpers::tsdemux;
use Harmless::M3U8;
use Harmless::Segment;
use Linux::Inotify2;
use Path::Class;

extends 'Emitron::Media::Base';
with 'Emitron::Media::Roles::Forker';

has webroot => ( isa => 'Str',               is => 'ro', required => 1 );
has usage   => ( isa => 'Str',               is => 'ro', required => 1 );
has config  => ( isa => 'ArrayRef[HashRef]', is => 'ro', required => 1 );

has ['vod', 'dynamic_duration'] => (
  isa      => 'Bool',
  is       => 'ro',
  required => 1,
  default  => 0
);

has _inotify => (
  isa     => 'Linux::Inotify2',
  is      => 'ro',
  lazy    => 1,
  default => sub {
    Linux::Inotify2->new
     or croak "Can't create inotify: $!";
  }
);

# vim:ts=2:sw=2:sts=2:et:ft=perl

=head1 NAME

Emitron::Media::Packager::HLS - HLS packager

=cut

sub start {
  my $self = shift;
  $self->fork(
    sub {
      $self->_make_manifest;
      $self->_streams;
      debug "Polling...";
      1 while $self->_inotify->poll;
      debug "Child exiting";
    }
  );
}

sub stop { shift->kill_all }

sub _manifest {
  my $self = shift;
  join( '_', $self->name, @_ ) . '.m3u8';
}

sub manifest {
  my $self = shift;
  return file( $self->webroot, $self->_manifest )->stringify;
}

sub _make_manifest {
  my $self = shift;
  my $m3u8 = Harmless::M3U8->new;
  my @vpl  = ();

  $self->_with_config(
    sub {
      my $br = shift;
      push @vpl,
       {EXT_X_STREAM_INF => {
          PROGRAM_ID => 1,
          BANDWIDTH  => $br->{profile}{a}{bitrate} + $br->{profile}{v}{bitrate}
        },
        uri => $self->_manifest( $br->{name} ) };
    }
  );

  $m3u8->vpl( \@vpl );

  my $mf = $self->manifest;
  file($mf)->parent->mkpath;
  debug "Writing $mf";
  $m3u8->write($mf);
}

sub _with_config {
  my ( $self, $cb ) = @_;
  $cb->($_) for @{ $self->config };
}

sub _token { join '.', $$, int(time) }

sub _make_streams {
  my $self = shift;
  my @stm  = ();
  my $tsd
   = Emitron::Media::Helpers::tsdemux->new( globals => $self->globals );
  $self->_with_config(
    sub {
      my $br   = shift;
      my $id   = $br->{name};
      my $tok  = $self->_token;
      my $next = 0;
      my $mf   = file( $self->webroot, $self->_manifest($id) );
      my $name = join '_', $self->name, $id;
      my $dstd = dir( $self->webroot, $name );
      $dstd->mkpath;
      my $m3u8 = Harmless::M3U8->new;
      $m3u8->read($mf) if -e $mf;
      $m3u8->closed( $self->vod );
      # TODO: sanity check / merge existing pl
      $m3u8->meta(
        { EXT_X_TARGETDURATION => $self->globals->gop,
          EXT_X_VERSION        => 3,
          EXT_X_MEDIA_SEQUENCE => 0,
          EXT_X_PLAYLIST_TYPE  => $self->vod ? 'VOD' : 'EVENT',
        }
      );
      $m3u8->push_discontinuity;
      push @stm, { mf => $mf, m3u8 => $m3u8, br => $br };
      $self->_inotify->watch(
        $br->{dir},
        IN_CLOSE_WRITE,
        sub {
          my $evt      = shift;
          my $src      = $evt->fullname;
          my $duration = $self->globals->gop;
          if ( $self->dynamic_duration ) {
            my $inf = $tsd->scan($src);
            if ($inf) { $duration = $inf->{len} / 1000 }
            else      { warning "Can't find h264 stream in $src" }
          }
          my $segn = sprintf '%s.%08d.ts', $tok, ++$next;
          my $uri = join '/', $name, $segn;
          my $dst = file( $dstd, $segn );
          link $src, $dst or die "Can't link $src -> $dst: $!";
          $m3u8->push_segment(
            Harmless::Segment->new(
              title    => '',
              duration => $duration,
              uri      => $uri
            )
          );
          debug "Updating $mf to include $uri";
          $m3u8->write($mf);
          # TODO now we advertise fragment avail
        }
      );
    }
  );
  return \@stm;
}

sub _streams {
  my $self = shift;
  @{ $self->{_s} ||= $self->_make_streams };
}

sub _with_streams {
  my ( $self, $cb ) = @_;
  $cb->($_) for $self->_streams;
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

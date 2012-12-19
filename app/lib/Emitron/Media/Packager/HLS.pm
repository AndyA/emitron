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

has webroot => ( isa => 'Str', is => 'ro', required => 1 );
has config => ( isa => 'ArrayRef[HashRef]', is => 'ro', required => 1 );

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

=for reference

  on segment complete:
    link segment into place
    update m3u8

  Stream config looks like

  [
    {
      profile => {
        a => {
          profile => "aac_lc",
          rate    => 44100,
          bitrate => 96000
        },
        v => {
          rate    => 25,
          profile => "main",
          width   => 512,
          bitrate => 400000,
          level   => 3,
          height  => 288
        }
      },
      order   => 1,
      name    => "p40",
      segment => "%08d.ts",
      dir => "/tmp/emitron/job.orac_pc_hd_lite.7175.1355247644.496/p40"
    },
    {
      profile => {
        a => {
          profile => "aac_lc",
          rate    => 44100,
          bitrate => 96000
        },
        v => {
          rate    => 25,
          profile => "main",
          width   => 704,
          bitrate => 1200000,
          level   => 3,
          height  => 396
        }
      },
      order   => 2,
      name    => "p60",
      segment => "%08d.ts",
      dir => "/tmp/emitron/job.orac_pc_hd_lite.7175.1355247644.496/p60"
    },
    {
      profile => {
        a => {
          profile => "aac_lc",
          rate    => 44100,
          bitrate => 128000
        },
        v => {
          rate    => 25,
          profile => "high",
          width   => 1280,
          bitrate => 3372000,
          level   => 4,
          height  => 720
        }
      },
      order   => 3,
      name    => "p80",
      segment => "%08d.ts",
      dir => "/tmp/emitron/job.orac_pc_hd_lite.7175.1355247644.496/p80"
    }
  ]

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

sub _make_manifest {
  my $self = shift;
  my $m3u8 = Harmless::M3U8->new;
  my @vpl  = ();

  $self->_with_config(
    sub {
      my $br = shift;
      push @vpl,
       {
        EXT_X_STREAM_INF => {
          PROGRAM_ID => 1,
          BANDWIDTH  => $br->{profile}{a}{bitrate}
           + $br->{profile}{v}{bitrate}
        },
        uri => $self->_manifest( $br->{name} )
       };
    }
  );

  $m3u8->vpl( \@vpl );

  my $mf = file( $self->webroot, $self->_manifest );
  $mf->parent->mkpath;
  debug "Writing $mf";
  $m3u8->write( $mf );
}

sub _with_config {
  my ( $self, $cb ) = @_;
  $cb->( $_ ) for @{ $self->config };
}

sub _token { join '.', $$, int( time ) }

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
      my $mf   = file( $self->webroot, $self->_manifest( $id ) );
      my $name = join '_', $self->name, $id;
      my $dstd = dir( $self->webroot, $name );
      $dstd->mkpath;
      my $m3u8 = Harmless::M3U8->new;
      $m3u8->read( $mf ) if -e $mf;
      # TODO: sanity check / merge existing pl
      $m3u8->meta(
        {
          EXT_X_TARGETDURATION => $self->globals->gop,
          EXT_X_VERSION        => 3,
          EXT_X_MEDIA_SEQUENCE => 0
        }
      );
      $m3u8->push_discontinuity;
      push @stm, { mf => $mf, m3u8 => $m3u8, br => $br };
      $self->_inotify->watch(
        $br->{dir},
        IN_CLOSE_WRITE,
        sub {
          my $evt = shift;
          my $src = $evt->fullname;
          my $inf = $tsd->scan( $src );
          warning "Can't find h264 stream in $src" unless $inf;
          my $duration = $inf ? $inf->{len} : $self->globals->gop;
          my $segn = sprintf '%s.%08d.ts', $tok, ++$next;
          my $uri = join '/', $name, $segn;
          my $dst = file( $dstd, $segn );
          link $src, $dst or die "Can't link $src -> $dst: $!";
          $m3u8->push_segment(
            Harmless::Segment->new(
              title    => '',
              duration => $duration / 1000,
              uri      => $uri
            )
          );
          debug "Updating $mf to include $uri";
          $m3u8->write( $mf );
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
  $cb->( $_ ) for $self->_streams;
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

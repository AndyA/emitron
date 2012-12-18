package Emitron::Media::Encoder;

use Moose;

use Carp qw( confess carp );
use Emitron::Media::Globals;
use File::Temp;
use POSIX qw( mkfifo );
use Path::Class;
use String::ShellQuote;

extends 'Emitron::Media::Base';
with 'Emitron::Media::Roles::Forker';

has source => ( isa => 'Str',               is => 'ro', required => 1 );
has config => ( isa => 'ArrayRef[HashRef]', is => 'ro', required => 1 );
has burnin => ( isa => 'Bool',              is => 'ro', default  => 0 );
has dog => ( isa => 'Str', is => 'ro' );

=head1 NAME

Emitron::Media::Encoder - A media stream encoder

=head1 INTERFACE

=head2 C<< start >>

Start the encode

=cut

sub start {
  my $self = shift;
  my @cmd  = $self->_build_cmds;
  $self->_stash( 'commands', @cmd );
  $self->bash( $_ ) for @cmd;
}

sub _stash {
  my ( $self, $name, @lines ) = @_;
  my $fh = file( $self->tmp_dir, 'commands' )->openw;
  print $fh "$_\n" for @lines;
}

=head2 C<< stop >>

Stop the encode

=cut

sub stop { shift->kill_all }

sub _log {
  my $self = shift;
  return ' > ' . shell_quote( $self->_mk_log( @_ ) ) . ' 2>&1';
}

sub _build_cmds {
  my $self = shift;
  my @cmds = ();
  my $src  = $self->source;

  if ( $src =~ m{^rtsp://} ) {
    my $fifo = $self->_mk_fifo;
    push @cmds,
     shell_quote( $self->_gst_pipe( src => $src, dst => $fifo ) )
     . $self->_log( 'gst', 'pipe' );
    $src = $fifo;
  }

  my $pre_fifo = $self->_mk_fifo;

  push @cmds,
   shell_quote(
    $self->_ff_decoder(
      src => $src,
      dst => $pre_fifo,
      dog => $self->dog
    )
   ) . $self->_log( 'ffmpeg', 'pre' );

  my @tee_fifo = ();
  for my $cfg ( @{ $self->config } ) {
    file( $cfg->{destination} )->parent->mkpath;
    push @tee_fifo, my $tf = $self->_mk_fifo;
    push @cmds,
     shell_quote(
      $self->_ff_encoder(
        $cfg->{profile},
        src    => $tf,
        dst    => $cfg->{destination},
        burnin => $self->burnin
      )
     ) . $self->_log( 'ffmpeg', $cfg->{name} );
  }

  push @cmds,
   join( ' | ',
    shell_quote( cat => $pre_fifo ),
    shell_quote( tee => @tee_fifo ) )
   . ' > /dev/null';

  return @cmds;
}

sub _ff_decoder {
  my ( $self, %args ) = @_;
  my @extra = ();
  if ( defined $args{dog} ) {
    @extra = (
      -i              => $args{dog},
      '-r:v'          => $self->globals->frame_rate,
      -filter_complex => 'overlay=120:40'
    );
  }
  my $ar  = $self->globals->aspect_ratio;
  my @cmd = (
    $self->globals->ffmpeg,
    -vsync => 'cfr',
    -y     => -i => $args{src},
    '-r:v' => $self->globals->frame_rate,
    '-r:a' => $self->globals->audio_rate,
    -s     => $self->globals->full_screen,
    -vf    => "pad=ih*$ar->[0]/$ar->[1]:ih:(ow-iw)/2:(oh-ih)/2",
    @extra,
    -map     => '0:0',
    -map     => '0:1',
    -acodec  => 'pcm_s16le',
    -vcodec  => 'rawvideo',
    -pix_fmt => 'yuv420p',
    -f       => 'avi',
    $args{dst}
  );
  return @cmd;
}

sub _to_k { sprintf '%gk', $_[0] / 1000 }

sub _burnin {
  my ( $self, $profile ) = @_;

  my $sz   = join 'x', $profile->{v}{width}, $profile->{v}{height};
  my $br   = _to_k( $profile->{v}{bitrate} + $profile->{a}{bitrate} );
  my $cap  = join " ", '', $self->name, $sz, $br, '';
  my $rate = $self->globals->frame_rate;
  my $font = $self->globals->font;

  my $fs = 56;
  my $sh = 2;

  my $dt = join( ':',
    "fontcolor=white",              "fontsize=$fs",
    "fontfile=$font",               'shadowcolor=black@0.7',
    "shadowx=$sh",                  "shadowy=$sh",
    "x=9*W/10-tw",                  "y=8*H/10",
    "timecode='00\\:00\\:00\\:01'", "rate=$rate/1",
    "text='$cap'" );

  return "drawtext=$dt";
}

sub _ff_encoder {
  my ( $self, $profile, %args ) = @_;
  my $ar     = $self->globals->aspect_ratio;
  my $keyint = $self->globals->gop * $profile->{v}{rate};
  my $sz     = join 'x', $profile->{v}{width}, $profile->{v}{height};

  my @burn = $args{burnin} ? ( -vf => $self->_burnin( $profile ) ) : ();

  my @cmd = (
    $self->globals->ffmpeg,
    -vsync        => 'cfr',
    -f            => 'avi',
    -y            => -i => $args{src},
    -map          => '0:0',
    -map          => '0:1',
    -acodec       => $self->globals->acodec,
    -ac           => 2,
    '-r:a'        => $profile->{a}{rate},
    '-b:a'        => _to_k( $profile->{a}{bitrate} ),
    -vcodec       => $self->globals->vcodec,
    '-profile:v'  => $profile->{v}{profile},
    -preset       => 'veryfast',
    -sc_threshold => 0,
    -g            => int( $keyint ),
    -keyint_min   => int( $keyint / 2 ),
    '-r:v'        => $profile->{v}{rate},
    '-b:v'        => _to_k( $profile->{v}{bitrate} ),
    -s            => $sz,
    @burn,
    -flags          => '-global_header',
    -f              => 'segment',
    -segment_time   => $self->globals->gop,
    -segment_format => 'mpegts',
    -threads        => 0,
    $args{dst}
  );
  return @cmd;
}

sub _gst_pipe {
  my ( $self, %args ) = @_;
  return (
    $self->globals->gst_launch,    #
    'mpegtsmux', 'name=muxer', '!', 'filesink', "location=$args{dst}", #
    'rtspsrc', "location=$args{src}", 'name=src',                      #
    'src.', '!', 'rtpmp4gdepay', '!', 'queue', '!', 'muxer.',          #
    'src.', '!', 'rtph264depay', '!', 'queue', '!', 'muxer.'           #
  );
}

sub _uid { ++( shift->{uid} ) }

sub _mk_log {
  my ( $self, $type, $id ) = @_;
  return file( $self->tmp_dir, "$type.$id.log" );
}

sub _mk_fifo {
  my ( $self, $ext ) = @_;
  my $uid  = $self->_uid;
  my $name = defined $ext ? "fifo.$uid.$ext" : "fifo.$uid";
  my $fifo = file( $self->tmp_dir, $name );
  mkfifo( $fifo, 0700 ) or confess "Can't create $fifo: $!";
  return $fifo;
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

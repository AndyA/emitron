package Emitron::Media::Globals;

use Moose;

use FindBin;

=head1 NAME

Emitron::Media::Globals - Media related globals

=cut

has frame_rate => ( isa => 'Num', is => 'ro', default => 25 );
has audio_rate => ( isa => 'Num', is => 'ro', default => 48000 );
has resolution => ( isa => 'Num', is => 'ro', default => 1080 );
has gop        => ( isa => 'Num', is => 'ro', default => 4 );
has acodec     => ( isa => 'Str', is => 'ro', default => 'libfaac' );
has vcodec     => ( isa => 'Str', is => 'ro', default => 'libx264' );

# Programs

has bash       => ( isa => 'Str', is => 'ro', default => '/bin/bash' );
has ffmpeg     => ( isa => 'Str', is => 'ro', default => 'ffmpeg' );
has gst_launch => ( isa => 'Str', is => 'ro', default => 'gst-launch' );
has tsdemux    => ( isa => 'Str', is => 'ro', default => 'tsdemux' );

has home => (
  isa     => 'Str',
  is      => 'ro',
  default => "$FindBin::Bin/.."
);

has font => (
  isa     => 'Str',
  is      => 'ro',
  lazy    => 1,
  default => sub { shift->home . '/fonts/Envy Code R.ttf' }
);

has aspect_ratio => (
  traits  => ['Array'],
  isa     => 'ArrayRef[Int]',
  is      => 'ro',
  default => sub { [16, 9] },
  handles => { aspect_ratio_str => 'join' }
);

sub gop_frames {
  my $self = shift;
  return $self->gop * $self->frame_rate;
}

sub width_from_height {
  my ( $self, $height ) = @_;
  my $ar = $self->aspect_ratio;
  return $height * $ar->[0] / $ar->[1];
}

sub full_screen {
  my $self = shift;
  my $sep = @_ ? shift : 'x';
  return join $sep, $self->width_from_height( $self->resolution ),
   $self->resolution;
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

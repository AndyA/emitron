package Lintilla::Image::Scaler;

use Moose;

use GD;
use List::Util qw( min max );
use Path::Class;

=head1 NAME

Lintilla::Image::Scaler - Scale / crop / pad an image

=cut

has ['in_file', 'out_file'] => ( is => 'ro', required => 1 );
has spec => ( is => 'ro', isa => 'HashRef', required => 1 );

sub _fit {
  my $self = shift;
  my ( $iw, $ih, $mw, $mh ) = @_;
  my $sc = min( $mw / $iw, $mh / $ih );
  return ( int( $iw * $sc ), int( $ih * $sc ) );
}

sub create {
  my $self     = shift;
  my $in_file  = $self->in_file;
  my $out_file = $self->out_file;
  my $img      = GD::Image->new("$in_file");
  defined $img or die "Can't load $in_file";

  my $spec = $self->spec;
  my $out  = $self->out_file;
  my $tmp  = "$out.tmp";
  die "$tmp exists" if -e $tmp;

  file($tmp)->parent->mkpath;

  my ( $iw, $ih ) = $img->getBounds;
  if ( $iw > $spec->{width} || $ih > $spec->{height} ) {
    my ( $ow, $oh )
     = $self->_fit( $iw, $ih, $spec->{width}, $spec->{height} );
    my $thb = GD::Image->new( $ow, $oh, 1 );
    $thb->copyResampled( $img, 0, 0, 0, 0, $ow, $oh, $iw, $ih );
    my $of = file($tmp)->openw;
    $of->binmode;
    print $of $thb->jpeg(90);
  }
  else {
    link $in_file, $tmp or die "Can't link $in_file to $tmp: $!\n";
  }

  rename $tmp, "$out_file"
   or die "Can't link $tmp to $out_file: $!\n";

  return;
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

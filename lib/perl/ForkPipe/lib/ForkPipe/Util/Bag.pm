package ForkPipe::Util::Bag;

use Moose;

use Scalar::Util qw( refaddr );

=head1 NAME

ForkPipe::Util::Bag - A bag of references

=cut

sub add {
  my ( $self, @elt ) = @_;
  for my $elt (@elt) {
    $self->{ refaddr($elt) } = $elt;
  }
}

sub remove {
  my ( $self, @elt ) = @_;
  for my $elt (@elt) {
    delete $self->{ refaddr($elt) };
  }
}

sub elements { values %{ $_[0] } }

sub contains {
  my ( $self, @elt ) = @_;
  for my $elt (@elt) {
    return unless exists $self->{ refaddr($elt) };
  }
  return 1;
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

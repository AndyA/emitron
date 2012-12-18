package ForkPipe::Role::Stats;

use Moose::Role;

=head1 NAME

ForkPipe::Role::Stats - Gather stats

=cut

has stats => (
  isa      => 'HashRef',
  is       => 'rw',
  required => 1,
  default  => sub { {} }
);

sub count {
  my $st  = shift->stats;
  my %arg = @_;
  while ( my ( $k, $v ) = each %arg ) {
    $st->{$k} += $v;
  }
  return;
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

package Emitron::Message;

use Moose;

use Emitron::Logger;
use Storable qw( store_fd fd_retrieve freeze thaw );

has msg    => ( is  => 'ro',  required => 1 );
has type   => ( isa => 'Str', is       => 'ro', required => 1 );
has source => ( isa => 'Str', is       => 'ro', default => 'internal' );
has worker => ( isa => 'Num', is       => 'ro', default => sub { $$ } );

=head1 NAME

Emitron::Message - A message

=cut

sub from_raw {
  my ( $class, $raw ) = @_;
  return $raw if UNIVERSAL::can( $raw, 'isa' ) && $raw->isa($class);
  return $class->new(%$raw);
}

sub get_raw {
  my $self = shift;
  return {%$self};
}

sub is_safe { shift->source eq 'internal' }

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

package Emitron::Worker::Drone;

use Moose;

use Emitron::Logger;

extends qw( Emitron::Worker::Base );

has despatcher => (
  isa      => 'Emitron::MessageDespatcher',
  is       => 'ro',
  required => 1
);

=head1 NAME

Emitron::Worker::Drone - Process messages

=cut

sub run {
  my $self = shift;
  while ( my $msg = $self->get_message ) {
    $self->despatcher->despatch( $msg );
  }
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

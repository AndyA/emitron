package Emitron::Worker::Script;

use Moose;

extends 'Emitron::Worker::Base';

=head1 NAME

Emitron::Worker::Script - The worker wrapper for a script.

=cut

sub run {
  my $self = shift;
  $self->handle_messages;
  $self->handle_events;
  $self->em->poll( 10 ) while 1;
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

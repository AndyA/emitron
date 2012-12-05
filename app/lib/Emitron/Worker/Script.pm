package Emitron::Worker::Script;

use Moose;

extends 'Emitron::Worker::Base';

=head1 NAME

Emitron::Worker::Script - The worker wrapper for a script.

=cut

sub run {
  my $self = shift;
  while ( my $msg = $self->get_message ) {
    $self->despatcher->despatch( $msg );
  }
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

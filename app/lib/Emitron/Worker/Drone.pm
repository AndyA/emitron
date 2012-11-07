package Emitron::Worker::Drone;

use strict;
use warnings;

use Emitron::Logger;

use base qw( Emitron::Worker::Base );

use accessors::ro qw( despatcher );

=head1 NAME

Emitron::Worker::Drone - Process messages

=cut

sub run {
  my $self = shift;
  while ( my $msg = $self->get_message ) {
    $self->despatcher->despatch($msg);
  }
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

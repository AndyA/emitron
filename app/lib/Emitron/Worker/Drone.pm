package Emitron::Worker::Drone;

use strict;
use warnings;

use Emitron::Logger;

use base qw( Emitron::Worker::Base );

=head1 NAME

Emitron::Worker::Drone - Process messages

=cut

sub run {
  my ( $self, $get, $wtr ) = @_;
  while ( my $msg = $get->() ) {
    debug 'Got message, type: ', $msg->type, ', source: ',
     $msg->source, ', msg: ', $msg->msg;
  }
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

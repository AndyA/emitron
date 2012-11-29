package Emitron::Core;

use strict;
use warnings;

=head1 NAME

Emitron::Core - Core command set

=cut

# TODO this needs to have access to the message and event queues.

sub new { bless {}, shift }

sub encode_start {
  my $self = shift;
}

sub encode_stop {
  my $self = shift;
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

package Emitron::Worker::Base;

use strict;
use warnings;

=head1 NAME

Emitron::Worker::Base - A worker

=cut

sub new {
  my $class = shift;
  return bless {@_}, $class;
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

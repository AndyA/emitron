package Emitron::Handler::Base;

use strict;
use warnings;

=head1 NAME

Emitron::Handler::Base - A message handler

=cut

sub new {
  my $class = shift;
  return bless {@_}, $class;
}

sub subscribe {
  my ( $self, $desp ) = @_;
  die;
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

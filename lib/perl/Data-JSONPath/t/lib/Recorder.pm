package Recorder;

use strict;
use warnings;

=head1 NAME

Recorder - Recall calls to a callback

=cut

sub new { bless [], shift }

sub callback {
  my $self = shift;
  sub { push @$self, [@_] }
}

sub log { [splice @{ $_[0] }] }

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

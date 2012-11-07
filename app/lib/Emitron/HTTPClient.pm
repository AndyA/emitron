package Emitron::HTTPClient;

use strict;
use warnings;

use LWP::UserAgent;

=head1 NAME

Emitron::HTTPClient - Base class for Emitron HTTP clients

=cut

sub ua {
  my $self = shift;
  return $self->{ua} ||= LWP::UserAgent->new;
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

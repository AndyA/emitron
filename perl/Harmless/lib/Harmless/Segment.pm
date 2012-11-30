package Harmless::Segment;

use strict;
use warnings;

use XML::LibXML::XPathContext;
use XML::LibXML;

=head1 NAME

Harmless::Segment - An HLS segment

=cut

use accessors::ro qw( uri );

sub new {
  my $class = shift;
  return bless {@_}, $class;
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

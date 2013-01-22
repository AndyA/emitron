#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long;
use JSON;

my $HDR = 0;
GetOptions( 'h' => \$HDR ) or die;

my $ds = decode_json do { local $/; <> };
for my $sym ( sort keys %$ds ) {
  print "extern " if $HDR;
  print "const char *$sym";
  print " = \"", to_c( encode_json $ds->{$sym} ), "\"" unless $HDR;
  print ";\n";
}

sub to_c {
  my $s = shift;
  $s =~ s/(["\\])/\\$1/g;
  return $s;
}

# vim:ts=2:sw=2:sts=2:et:ft=perl


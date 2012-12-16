#!/usr/bin/env perl

use strict;
use warnings;

sub define($$) {
  my ( $n, $v ) = @_;
  $v = qq{"$v"} unless $v =~ /^-?\d+(?:\.\d+)?$/;
  print "#define $n $v";
}

# vim:ts=2:sw=2:sts=2:et:ft=perl


#!/usr/bin/env perl

use strict;
use warnings;

use Time::HiRes qw( sleep );

$| = 1;

my $fn = shift or die;

open my $fh, '<', $fn or die "Can't read $fn: $!\n";

my @spin  = qw( - / | \ );
my $total = 0;
while () {
  my $got = sysread( $fh, my $buf, 500000 );
  die $! unless defined $got;
  last   unless $got;
  $total += $got;
  my $sp = shift @spin;
  push @spin, $sp;
  printf "\r$sp %10lu ", $total;
  sleep 0.5;
}
print "\n";

# vim:ts=2:sw=2:sts=2:et:ft=perl


#!/usr/bin/env perl

use strict;
use warnings;

use Number::Bytes::Human qw( format_bytes );

my @fr = ( 25, 30, 50, 60 );
my @fh = ( 1080, 720, 576 );
my %px = ( YUV420 => 1.5 );

for my $fh ( @fh ) {
  my $fw = $fh * 16 / 9;
  for my $px ( sort { $px{$a} <=> $px{$b} || $a cmp $b } keys %px ) {
    my $pxr = $px{$px};
    my $by  = $fw * $fh * $pxr;
    printf "%4d x %4d %-8s (frame: %s)\n", $fw, $fh, $px,
     format_bytes( $by );
    for my $fr ( @fr ) {
      printf "  %3d fps: %s/s\n", $fr, format_bytes( $by * $fr );
    }
  }
}

# vim:ts=2:sw=2:sts=2:et:ft=perl

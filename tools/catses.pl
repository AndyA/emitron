#!/usr/bin/env perl

use strict;
use warnings;

use File::Basename qw( basename );
use POSIX qw( strftime );
use Path::Class;
use Set::IntSpan::Fast;

catses($_) for @ARGV;

sub catses {
  my $dir = shift;
  my $out = basename $dir;
  dir($out)->mkpath;
  my (%sess);
  opendir my $dh, $dir or die "Can't read $dir: $!\n";
  for my $frag ( readdir $dh ) {
    my $fn = basename $frag;
    next unless $fn =~ /^(\d+)\.(\d+)\.(\d+)\.ts$/;
    my ( $pid, $tm, $idx ) = ( $1, $2, $3 );
    $sess{$tm}{name} ||= file( $dir, "$pid.$tm.%0" . length($idx) . "d.ts" );
    $sess{$tm}{set} ||= Set::IntSpan::Fast->new;
    $sess{$tm}{set}->add( $idx * 1 );
  }
  for my $tm ( sort { $a <=> $b } keys %sess ) {
    my $ts = strftime '%Y%m%d-%H%M%S', gmtime $tm;
    my $iter = $sess{$tm}{set}->iterate_runs;
    while ( my ( $from, $to ) = $iter->() ) {
      my $first = sprintf $sess{$tm}{name}, $from;
      my $fn = file( $out, "$ts-${from}to$to.ts" );
      print "$first -> $fn\n";
      system tailpipe => -i => -t => 1 => -o => "$fn", $first;
    }
  }
}

# vim:ts=2:sw=2:sts=2:et:ft=perl


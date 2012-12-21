#!/usr/bin/env perl

use strict;
use warnings;

use POSIX qw( strftime );

my $cmd = join ' | ',
 q{for fd in /proc/*/fd/*; do readlink -f $fd; done},
 q{grep :inotify};

my %by_proc = ();
{
  open my $fh, '-|', $cmd or die "Can't run $cmd: $!";
  while (<$fh>) {
    next unless m{^/proc/(\d+)/};
    $by_proc{$1}++;
  }
  close $fh or die "$cmd failed: $?";
}

print "INUSE\n";

{
  my $ts   = strftime '%Y/%m/%d %H:%M:%S', gmtime time;
  my $tot  = 0;
  my @pids = sort { $by_proc{$a} <=> $by_proc{$b} || $a <=> $b }
   keys %by_proc;

  for my $pid (@pids) {
    chomp( my $ps = `ps hu $pid` );
    printf "%s [%5d] %s\n", $ts, $by_proc{$pid}, $ps;
    $tot += $by_proc{$pid};
  }
  printf "%s [%5d] %s\n", $ts, $tot, 'TOTAL';
}

# vim:ts=2:sw=2:sts=2:et:ft=perl


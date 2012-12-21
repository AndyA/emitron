#!/usr/bin/env perl

use strict;
use warnings;

use Time::HiRes qw( sleep );
use POSIX ":sys_wait_h";

sub f0rk(&) {
  my $cb  = shift;
  my $pid = fork;
  defined $pid or die "Can't fork: $!";
  exit $cb->() unless $pid;
  return $pid;
}

sub murder(@) {
  my @pid = @_;
  my $got = kill -2 => @pid;
  print "Signalled $got processe(s) out of ", scalar(@pid), "\n";
}

sub loiter(@) {
  my %pid = map { $_ => 1 } @_;
  while ( keys %pid ) {
    for my $pid ( keys %pid ) {
      my $got = waitpid $pid, WNOHANG;
      if ( $got > 0 ) {
        print "Reaped $got ($?)\n";
        print "Was expecting $pid\n" unless $pid == $got;
        delete $pid{$got};
      }
    }
    print "Still waiting for ",
     join( ', ', sort { $a <=> $b } keys %pid ), "\n"
     if keys %pid;
    sleep 0.25;
  }
}

my @pid = ();

print "Parent is $$\n";

push @pid, f0rk {
  setpgrp( 0, 0 );
  my $cpid = f0rk {
    while () {
      print "[$$] Child's child (pg)\n";
      sleep 2.73;
    }
  };

  while () {
    print "[$$] Child (pg)\n";
    sleep 1.32;
  }

  return 0;
};

local $SIG{TERM} = sub {
  print "[$$] Got SIGTERM\n";
  murder @pid;
  loiter @pid;
  exit;
};

local $SIG{INT} = sub {
  print "[$$] Got SIGINT\n";
  murder @pid;
  loiter @pid;
  exit;
};

sleep 100;
murder @pid;
loiter @pid;
print "Done\n";

# vim:ts=2:sw=2:sts=2:et:ft=perl


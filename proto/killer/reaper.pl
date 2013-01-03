#!/usr/bin/env perl

use strict;
use warnings;

use POSIX ":sys_wait_h";
use Time::HiRes qw( sleep );

my %KID = ();

sub mention(@) {
  my $ldr = "[$$] ";
  print "$ldr$_\n" for split /\n/, join '', @_;
}

sub _spawn {
  my $cb  = shift;
  my $pid = fork;
  defined $pid or die "Can't fork: $!\n";
  exit $cb->() unless $pid;
  return $pid;
}

sub spawn(&) {
  my $cb  = shift;
  my $pid = _spawn($cb);
  mention "Spawned ", $pid;
  $KID{$pid}++;
  return $pid;
}

sub reap() {
  my $pid = waitpid -1, WNOHANG;
  if ( $pid > 0 ) {
    if ( exists $KID{$pid} ) {
      mention "Reaped child: ", $pid;
      delete $KID{$pid};
    }
    else {
      mention "Reaped orphan: ", $pid;
    }
  }
}

spawn {
  setpgrp( 0, 0 );
  sleep 3;
};

while ( keys %KID ) {
  sleep 0.1;
  reap;
}

# vim:ts=2:sw=2:sts=2:et:ft=perl


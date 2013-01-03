#!/usr/bin/env perl

use strict;
use warnings;

use Time::HiRes qw( sleep );
use POSIX ":sys_wait_h";

sub mention(@) {
  my $ldr = "[$$] ";
  print "$ldr$_\n" for split /\n/, join '', @_;
}

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
  mention "Signalled $got processe(s) out of ", scalar(@pid);
}

sub loiter(@) {
  my %pid = map { $_ => 1 } @_;
  while ( keys %pid ) {
    my $got = waitpid -1, WNOHANG;
    if ( $got > 0 ) {
      delete $pid{$got};
      mention "Reaped $got ($?)";
      mention "Still waiting for ", join ', ', sort { $a <=> $b } keys %pid
       if keys %pid;
    }
    sleep 0.25;
  }
}

my @pid = ();

mention "Parent is $$";

sub work() {
  mention "Running ffmpeg";
  exec ffmpeg => -y => -i => '../../media/coast.ts',
   -acodec    => 'libfaac',
   -vcodec    => 'libx264',
   'coast.mp4';
}

push @pid, f0rk {
  my $cpid = f0rk {
    work;
  };

  while () {
    mention "Child (pg)";
    sleep 0.32;
  }

  return 0;
};

local $SIG{TERM} = sub {
  mention "Got SIGTERM";
  murder @pid;
  loiter @pid;
  exit;
};

local $SIG{INT} = sub {
  mention "Got SIGINT";
  murder @pid;
  loiter @pid;
  exit;
};

#sleep 4;
#murder @pid;
loiter @pid;
mention "Done";

# vim:ts=2:sw=2:sts=2:et:ft=perl


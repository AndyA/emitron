#!/usr/bin/env perl

use lib qw( lib );

use Moose;
use ForkPipe;
use Data::Dumper;

my $fp = ForkPipe->new;

if ( my $pid = $fp->fork ) {
  $fp->log("In parent, child is $pid");
  $fp->on(
    sub {
      my $msg = shift;
      $fp->log( "Got: ", dd($msg) );
      $msg->{sn}++;
      $fp->send($msg);
    }
  );
  $fp->send( { sn => 1 } );
  1 while $fp->poll(100);
  waitpid $pid, 0;
}
else {
  $fp->log("In child");
  $fp->on(
    sub {
      my $msg = shift;
      $fp->log( "Got: ", dd($msg) );
      $msg->{sn}++;
      sleep 2;
      $fp->send($msg);
    }
  );
  1 while $fp->poll(100);
  exit;
}

sub dd {
  my $obj = shift;
  chomp( my $dd
     = Data::Dumper->new( [$obj] )->Indent(2)->Quotekeys(0)->Useqq(1)
     ->Terse(1)->Dump );
  return $dd;
}

# vim:ts=2:sw=2:sts=2:et:ft=perl


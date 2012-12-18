#!/usr/bin/env perl

use lib qw( lib );

use Moose;
use ForkPipe;

my $fp = ForkPipe->new;

if ( my $pid = $fp->fork ) {
  print "$$ In parent, child is $pid\n";
  $fp->send( { msg => 'Hello, World' } );
  1 while $fp->poll( 100 );
  waitpid $pid, 0;
}
else {
  print "$$ In child\n";
  1 while $fp->poll( 100 );
  exit;
}

# vim:ts=2:sw=2:sts=2:et:ft=perl


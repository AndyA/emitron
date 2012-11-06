#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Emitron::Message;
use Emitron::Worker;
use Emitron::Runner;

my $emr = Emitron::Runner->new( workers => 3 );
for ( 1 .. 5 ) {
  $emr->enqueue(
    Emitron::Message->new( message => { id => $_, touched => 0 } ) );
}
$emr->run;

# vim:ts=2:sw=2:sts=2:et:ft=perl

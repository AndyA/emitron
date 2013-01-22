#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../perl/lib";

use Test::More;
use Dynatron::Client;

my $cl = Dynatron::Client->new;

$cl->send( { verb => "ping" } );

done_testing();

# vim:ts=2:sw=2:et:ft=perl


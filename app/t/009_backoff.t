#!perl

use strict;
use warnings;
use Test::More;

use Emitron::BackOff;

ok my $bo = Emitron::BackOff->new, 'constructed';
isa_ok $bo, 'Emitron::BackOff';

my $rise = 2**0.5;

is $bo->good, 1, "good 1";
is $bo->good, 1, "good 2";
is $bo->bad, $rise, "bad 1";
is $bo->bad, $rise**2, "bad 2";
is $bo->bad, $rise**3, "bad 3";
is $bo->good, 1, "good 3";
is $bo->bad, $rise, "bad 4";

done_testing();

# vim:ts=2:sw=2:et:ft=perl


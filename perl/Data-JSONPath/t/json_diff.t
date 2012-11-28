#!perl

use strict;
use warnings;

use Test::Differences;
use Test::More;
use DataDrivenTest;

use Data::JSONDiff;

ok 1, "that's ok";
ddt(
  'diff',
  't/data/diffpatch.json',
  sub {
    my $tc = shift;
    my $diff = json_diff( $tc->{a}, $tc->{b} );
    eq_or_diff $diff, $tc->{diff}, "$tc->{name}: diff";
  },
  readOnly => 1
);

done_testing();

# vim:ts=2:sw=2:et:ft=perl


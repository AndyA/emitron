#!perl

use strict;
use warnings;

use Test::Differences;
use Test::More;
use DataDrivenTest;

use Data::JSONPatch;

sub test_patch {
  my $tc = shift;
  my $got = json_patched( $tc->{a}, $tc->{diff} );
  eq_or_diff $got, $tc->{b}, "$tc->{name}: patched";
}

ddt( 'patch', 't/data/diffpatch.json', \&test_patch, readOnly => 1 );
ddt( 'patch (non diff data)',
  't/data/patchonly.json', \&test_patch, readOnly => 1 );

done_testing();

# vim:ts=2:sw=2:et:ft=perl


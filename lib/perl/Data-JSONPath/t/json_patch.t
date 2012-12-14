#!perl

use strict;
use warnings;

use Test::Differences;
use Test::More;
use DataDrivenTest;

use Data::JSONPatch;

{
  my $p = Data::JSONPatch->new( { foo => 1 } );
  eq_or_diff $p->data, { foo => 1 }, 'data';
  $p->data( [] );
  eq_or_diff $p->data, [], 'set data';
}

{
  my $p = Data::JSONPatch->new;
  is $p->patch_path( { path => '$.foo' } ), '$.foo',
   'patch_path: $.foo';
  is $p->patch_path( { element => '$.foo' } ),
   '$.foo',
   'patch_path: $.foo';
  is $p->patch_path( { path => '$', element => 'foo' } ), '$.foo',
   'patch_path: $.foo';
}

sub test_patch {
  my $tc = shift;
  my $got = json_patched( $tc->{a}, $tc->{diff} );
  eq_or_diff $got, $tc->{b}, "$tc->{name}: patched";
}

sub test_oo {
  my $tc = shift;
  my $p  = Data::JSONPatch->new( $tc->{a} );
  $p->patch( $tc->{diff} );
  eq_or_diff $p->data, $tc->{b}, "$tc->{name}: patched";
}

sub test_with {
  my $cb = shift;
  ddt( 'patch',                 't/data/diffpatch.json', $cb );
  ddt( 'patch (non diff data)', 't/data/patchonly.json', $cb );
}

test_with( \&test_patch );
test_with( \&test_oo );

done_testing();

# vim:ts=2:sw=2:et:ft=perl


#!perl

use strict;
use warnings;

use Test::Differences;
use Test::More;
use DataDrivenTest;

use Data::JSONPath;

ddt(
  'toker',
  't/data/path.json#toker',
  sub {
    my $tc = shift;
    my $t  = Data::JSONPath->toker( $tc->{path} );
    for my $want ( @{ $tc->{want} } ) {
      my $tok = $t->();
      eq_or_diff $tok, $want, "$tc->{path}: token $tok->{m}[0]";
    }
    is $t->(), undef, "$tc->{path}: end of stream";
  },
  readOnly => 1
);

done_testing();

# vim:ts=2:sw=2:et:ft=perl


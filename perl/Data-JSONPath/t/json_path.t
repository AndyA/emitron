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

ddt(
  'match',
  't/data/path.json#match',
  sub {
    my $tc  = shift;
    my $jp  = Data::JSONPath->new( $tc->{path} );
    my $got = $jp->match( $tc->{test} );
    eq_or_diff $got, $tc->{want},
     "$tc->{name}: $tc->{path} ?= $tc->{test}";
  },
  readOnly => 1
);

ddt(
  'capture',
  't/data/path.json#capture',
  sub {
    my $tc  = shift;
    my $jp  = Data::JSONPath->new( $tc->{abstract} );
    my $got = $jp->capture( $tc->{concrete} );
    eq_or_diff $got, $tc->{want}, "$tc->{name}";
  },
  readOnly => 1
);

done_testing();

# vim:ts=2:sw=2:et:ft=perl


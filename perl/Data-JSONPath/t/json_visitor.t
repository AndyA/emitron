#!perl

use strict;
use warnings;

use Test::Differences;
use Test::More;
use DataDrivenTest;

use Data::JSONVisitor;

sub resolve_path {
  my ( $data, $path ) = @_;
  my @p = split /\./, $path;
  my $ds = { '$' => $data };
  my ( $pds, $key );
  while ( @p ) {
    $pds = $ds;
    $key = shift @p;
    $ds  = 'ARRAY' eq ref $ds ? $ds->[$key] : $ds->{$key};
  }
  $key *= 1 if 'ARRAY' eq ref $pds;
  return [ $path, $ds, $pds, $key ];
}

ddt(
  'iter',
  't/data/path.json#iter',
  sub {
    my $tc = shift;
    my $p  = Data::JSONVisitor->new( $tc->{data} );
    my $ii = $p->iter( $tc->{path} );
    for my $w ( @{ $tc->{want} } ) {
      my $want = resolve_path( $tc->{data}, $w );
      my $got = $ii->();
      eq_or_diff $got, $want, "$tc->{name}: $w";
    }
    is $ii->(), undef, "$tc->{name}: iter exhausted";
  },
  readOnly => 1
);

done_testing();

# vim:ts=2:sw=2:et:ft=perl

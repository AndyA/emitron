#!perl

use strict;
use warnings;

use Test::Differences;
use Test::More;
use DataDrivenTest;
use Recorder;

use Data::JSONVisitor;

sub resolve_path {
  my ( $data, $path ) = @_;
  my @p = split /\./, $path;
  my $ds = { '$' => $data };
  my ( $pds, $key );
  while (@p) {
    $pds = $ds;
    $key = shift @p;
    $ds  = 'ARRAY' eq ref $ds ? $ds->[$key] : $ds->{$key};
  }
  $key *= 1 if 'ARRAY' eq ref $pds;
  return [$path, $ds, $pds, $key];
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

ddt(
  'vivify',
  't/data/path.json#vivify',
  sub {
    my $tc = shift;
    my $p  = Data::JSONVisitor->new( $tc->{data} );
    my $ii = $p->iter( $tc->{path}, 1 );
    1 while $ii->();
    eq_or_diff $p->data, $tc->{want}, "$tc->{name}: vivified";
  }
);

ddt(
  'set',
  't/data/path.json#set',
  sub {
    my $tc = shift;
    my $p  = Data::JSONVisitor->new( $tc->{data} );
    $p->set( $tc->{path}, $tc->{value} );
    eq_or_diff $p->data, $tc->{want}, "$tc->{name}: set";
  }
);

ddt(
  'each',
  't/data/path.json#each',
  sub {
    my $tc   = shift;
    my $rec  = Recorder->new;
    my $p    = Data::JSONVisitor->new( $tc->{in} );
    my @want = ();
    for my $w ( @{ $tc->{want} } ) {
      push @want, resolve_path( $tc->{in}, $w );
    }
    $p->each( $tc->{path}, $rec->callback );
    eq_or_diff $rec->log, \@want, "$tc->{name}: each";
  }
);

done_testing();

# vim:ts=2:sw=2:et:ft=perl

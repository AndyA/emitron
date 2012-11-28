#!perl

use strict;
use warnings;

use Test::Differences;
use Test::More;
use DataDrivenTest;
use Recorder;

use Data::JSONTrigger;

{
  my $jt  = Data::JSONTrigger->new;
  my $rec = Recorder->new;

  $jt->on( '$.foo',   $rec->callback );
  $jt->on( '$.bar.*', $rec->callback );

  $jt->fire( '$.foo.0', "Hello, World" );
  $jt->fire( '$.bar.boffle', 1, 2, 3 );
  $jt->fire( '$.baz.nomatch' );
  my $want = [
    # Comment to foil perltidy
    [ '$.foo.0', "Hello, World" ],
    [ '$.bar.boffle', 1, 2, 3 ],
  ];
  eq_or_diff $rec->log, $want, "fire";
}

ddt(
  'changeSet',
  't/data/trigger.json#changeSet',
  sub {
    my $tc = shift;
    my $jt = Data::JSONTrigger->new( $tc->{data} );
    my $cs = $jt->change_set( $tc->{patch} );
    eq_or_diff $cs->{list}->data, $tc->{list}, "$tc->{name}: list";
  }
);

ddt(
  'trigger',
  't/data/trigger.json#trigger',
  sub {
    my $tc  = shift;
    my $jt  = Data::JSONTrigger->new( $tc->{data} );
    my $rec = Recorder->new;
    for my $on ( @{ $tc->{on} } ) {
      $jt->on( $on, $rec->callback );
    }
    $jt->patch( $tc->{patch} );
    eq_or_diff $rec->log, $tc->{want}, "$tc->{name}: trigger";
  }
);

ddt(
  'model',
  't/data/trigger.json#model',
  sub {
    my $tc  = shift;
    my $jt  = Data::JSONTrigger->new( $tc->{data} );
    my $rec = Recorder->new;
    for my $on ( @{ $tc->{on} } ) {
      $jt->on( $on, $rec->callback );
    }
    if    ( $tc->{patch} )   { $jt->patch( $tc->{patch} ) }
    elsif ( $tc->{newdata} ) { $jt->data( $tc->{newdata} ) }
    eq_or_diff $rec->log, $tc->{want}, "$tc->{name}: model";
  }
);

sub test_patch {
  my $tc = shift;
  my $p  = Data::JSONTrigger->new( $tc->{a} );
  $p->patch( $tc->{diff} );
  eq_or_diff $p->data, $tc->{b}, "$tc->{name}: patched";
}

ddt( 'patch',                 't/data/diffpatch.json', \&test_patch );
ddt( 'patch (non diff data)', 't/data/patchonly.json', \&test_patch );

done_testing();

# vim:ts=2:sw=2:et:ft=perl

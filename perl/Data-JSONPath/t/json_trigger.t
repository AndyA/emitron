#!perl

use strict;
use warnings;

use Test::Differences;
use Test::More;
use DataDrivenTest;
use Recorder;

use Data::JSONTrigger;

{
  ok my $jt = Data::JSONTrigger->new, 'new';
  isa_ok $jt, 'Data::JSONTrigger';
  my $rec = Recorder->new;

  is $jt->has_trigger, 0, 'has_trigger == 0';

  $jt->on( '$.foo',   $rec->callback );
  $jt->on( '$.bar.*', $rec->callback )
   ->on( '$.*.bink', $rec->callback, 'aGroup' );

  is $jt->has_trigger, 3, 'has_trigger == 3';

  my $fire = sub {
    $jt->fire( '$.foo.0', "Hello, World" )
     ->fire( '$.bar.boffle', 1, 2, 3 );
    $jt->fire( '$.baz.bink' );
    $jt->fire( '$.baz.nomatch' );
    $jt->fire( '*$.bar.bink' );
  };

  $fire->();

  {
    my $want = [
      # Comment to foil perltidy
      [ '$.foo.0', "Hello, World" ],
      [ '$.bar.boffle', 1, 2, 3 ],
      ['$.baz.bink'],
      ['$.bar.bink'],
      ['$.bar.bink'],
    ];
    eq_or_diff $rec->log, $want, "fire";
  }

  $jt->off( path => '$.foo' )->off( group => 'aGroup' );

  $fire->();

  {
    my $want = [
      # Comment to foil perltidy
      [ '$.bar.boffle', 1, 2, 3 ],
      ['$.bar.bink'],
    ];
    eq_or_diff $rec->log, $want, "fire";
  }
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

#!perl

use strict;
use warnings;
use Test::More tests => 16;

use Celestian::Model::Base;
use Data::Dumper;

package Thing;

use base qw( Celestian::Model::Base );

sub kind { 'thing' }
sub name { 'Celia' }

package Thong;

use base qw( Celestian::Model::Base );

sub kind { 'thong' }
sub name { 'Frank' }

package main;

{
  my $obj = Celestian::Model::Base->new;
  isa_ok $obj, 'Celestian::Model::Base';

  $obj->on( foo => sub { } );
  is_deeply [ $obj->list_event_handlers ], ['default:foo'],
   'default handler';
  $obj->on( 'mystuff:foo' => sub { }, 'mystuff:bar' => sub { } );
  is_deeply [ $obj->list_event_handlers ],
   [ 'mystuff:bar', 'default:foo', 'mystuff:foo' ],
   'mystuff handler';
  $obj->off( '*:foo' );
  is_deeply [ $obj->list_event_handlers ],
   ['mystuff:bar'],
   'delete foo handler';
}

{
  my $obj        = Celestian::Model::Base->new;
  my $call_index = 0;
  my @event_log  = ();

  my $note_event = sub {
    push @event_log, { index => ++$call_index, args => [@_] };
  };

  $obj->on( foo => $note_event );
  $obj->raise( foo => 1, 2, 3 );
  is_deeply [@event_log], [ { index => 1, args => [ 1, 2, 3 ] } ],
   'event 1';

  @event_log = ();
  $obj->on( 'test:foo' => $note_event );
  $obj->raise( foo => 4 );
  is_deeply [@event_log],
   [ { index => 2, args => [4] }, { index => 3, args => [4] }, ],
   'event 2';

  @event_log = ();
  $obj->off( 'default:*' );
  $obj->raise( foo => 5 );
  is_deeply [@event_log], [ { index => 4, args => [5] }, ], 'event 2';
}

{
  my $obj = Celestian::Model::Base->new;
  my @log = ();
  $obj->on( added         => sub { push @log, 'added' } );
  $obj->on( added_thing   => sub { push @log, 'added_thing' } );
  $obj->on( added_thong   => sub { push @log, 'added_thong' } );
  $obj->on( removed       => sub { push @log, 'removed' } );
  $obj->on( removed_thing => sub { push @log, 'removed_thing' } );
  $obj->on( removed_thong => sub { push @log, 'removed_thong' } );
  my $tt1 = Thing->new;
  my $tt2 = Thong->new;

  $obj->add( $tt1 );
  is_deeply [@log], [ 'added_thing', 'added' ], 'added 1';

  @log = ();
  $obj->add( $tt1, $tt2 );
  is_deeply [@log], [ 'added_thong', 'added' ], 'added 2';

  @log = ();
  $obj->add( $tt1, $tt2 );
  is_deeply [@log], [], 'added 3';

  @log = ();
  $obj->remove( $tt1 );
  is_deeply [@log], [ 'removed', 'removed_thing' ], 'removed 1';

  @log = ();
  $obj->remove( $tt1 );
  is_deeply [@log], [], 'removed 2';

  @log = ();
  $obj->remove( $tt2 );
  is_deeply [@log], [ 'removed', 'removed_thong' ], 'removed 3';
}
{
  my $obj = Celestian::Model::Base->new;
  my $tt1 = Thing->new;
  my $tt2 = Thong->new;
  $obj->add( $tt1, $tt2 );
  is_deeply [ where( $obj ) ], [ $tt1, $tt2 ], 'selected all';
  is_deeply [ where( $obj, kind => 'thing' ) ], [$tt1],
   'selected thing';
  is_deeply [ where( $obj, name => 'Frank' ) ], [$tt2],
   'selected Frank';
}

sub where {
  my $obj = shift;
  my @r   = ();
  $obj->select( @_ )->witheach( sub { push @r, $_[1] } );
  return @r;
}

# vim:ts=2:sw=2:et:ft=perl

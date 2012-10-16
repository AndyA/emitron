#!perl

use strict;
use warnings;
use Test::More tests => 7;

use NewStream::Model::Base;
use Data::Dumper;

{
  my $obj = NewStream::Model::Base->new;
  isa_ok $obj, 'NewStream::Model::Base';

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
  my $obj        = NewStream::Model::Base->new;
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
  is_deeply [@event_log],
   [
    { index => 4, args => [5] },
   ],
   'event 2';
}

# vim:ts=2:sw=2:et:ft=perl

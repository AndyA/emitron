#!perl

use strict;
use warnings;

use Data::Dumper;

use Test::More tests => 11;
use Test::Differences;

use Emitron::MessageDespatcher;

sub rec::new { bless [], shift }

sub rec::cb {
  my $self = shift;
  sub { push @$self, \@_ }
}

sub rec::log { [ splice @{ $_[0] } ] }

sub msg::new { my $c = shift; bless {@_}, $c }
sub msg::type { shift->{type} }

{
  ok my $md = Emitron::MessageDespatcher->new, "created";
  isa_ok $md, 'Emitron::MessageDespatcher';

  my $rec1 = rec->new;
  my $rec2 = rec->new;
  my $rec3 = rec->new;
  my $rec4 = rec->new;
  my $rec5 = rec->new;
  my $rec6 = rec->new;

  $md->on( foo => $rec1->cb );
  $md->on( bar => $rec1->cb );
  $md->on( bar => $rec1->cb, 'backup' );
  $md->on( baz => $rec1->cb, 'backup' );

  $md->on( foo => $rec2->cb );
  $md->on( baz => $rec2->cb );

  $md->on( qr{^(foo)$} => $rec3->cb, 'qr' );

  $md->on( qr{^(\w+)$} => $rec4->cb, 'qr' );

  $md->on( '*' => $rec5->cb, 'wild' );

  $md->on( 'foo.*.bar.*' => $rec6->cb, 'wild' );

  $md->despatch( msg->new( type => 'foo' ) );
  $md->despatch( msg->new( type => 'bar' ) );
  $md->despatch( msg->new( type => 'foo.hello.bar.world' ) );
  $md->despatch( msg->new( type => 'foo.hello.bar' ) );
  $md->despatch( msg->new( type => 'foo.0.bar.0' ) );
  $md->despatch( msg->new( type => 'foo.0.0.bar.0' ) );

  eq_or_diff $rec1->log,
   [
    [ bless { type => 'foo' }, 'msg' ],
    [ bless { type => 'bar' }, 'msg' ],
    [ bless { type => 'bar' }, 'msg' ]
   ],
   "messages to rec1";

  eq_or_diff $rec2->log,
   [ [ bless { type => 'foo' }, 'msg' ], ],
   "messages to rec2";

  eq_or_diff $rec3->log,
   [ [ bless( { type => 'foo' }, 'msg' ), 'foo' ], ],
   "messages to rec3";

  eq_or_diff $rec4->log,
   [
    [ bless( { type => 'foo' }, 'msg' ), 'foo' ],
    [ bless( { type => 'bar' }, 'msg' ), 'bar' ],
   ],
   "messages to rec4";

  eq_or_diff $rec5->log,
   [
    [ bless( { type => 'foo' }, 'msg' ), 'foo' ],
    [ bless( { type => 'bar' }, 'msg' ), 'bar' ],
   ],
   "messages to rec5";

  eq_or_diff $rec6->log,
   [
    [
      bless( { type => 'foo.hello.bar.world' }, 'msg' ), 'hello',
      'world'
    ],
    [ bless( { type => 'foo.0.bar.0' }, 'msg' ), '0', '0' ],
   ],
   "messages to rec6";

  $md->off( name => 'foo' );

  $md->despatch( msg->new( type => 'foo' ) );
  $md->despatch( msg->new( type => 'bar' ) );
  $md->despatch( msg->new( type => 'bar' ) );

  eq_or_diff $rec1->log,
   [
    [ bless { type => 'bar' }, 'msg' ],
    [ bless { type => 'bar' }, 'msg' ],
    [ bless { type => 'bar' }, 'msg' ],
    [ bless { type => 'bar' }, 'msg' ],
   ],
   "messages to rec1 after off foo";

  eq_or_diff $rec2->log, [], "messages to rec2 after off foo";

  $md->off( group => 'wild' )->off( group => 'backup', name => 'bar' );

  $md->despatch( msg->new( type => 'bar' ) );
  $md->despatch( msg->new( type => 'baz' ) );

  eq_or_diff $rec1->log,
   [
    [ bless { type => 'bar' }, 'msg' ],
    [ bless { type => 'baz' }, 'msg' ],
   ],
   "messages to rec1 after off backup bar";
}

# vim:ts=2:sw=2:et:ft=perl


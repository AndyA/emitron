#!perl

use strict;
use warnings;
use Test::More tests => 4;

use Emitron::MessageDespatcher;

sub rec::new { bless [], shift }

sub rec::cb {
  my $self = shift;
  sub { push @$self, \@_ }
}

sub rec::log { [ @{ $_[0] } ] }

sub msg::new { my $c = shift; bless {@_}, $c }
sub msg::type { shift->{type} }

{
  ok my $md = Emitron::MessageDespatcher->new, "created";
  isa_ok $md, 'Emitron::MessageDespatcher';

  my $rec1 = rec->new;
  my $rec2 = rec->new;

  $md->on( 'foo', $rec1->cb );
  $md->on( 'foo', $rec2->cb );
  $md->on( 'bar', $rec1->cb );
  $md->on( 'bar', $rec1->cb );

  $md->despatch( msg->new( type => 'foo' ) );
  $md->despatch( msg->new( type => 'bar' ) );

  is_deeply $rec1->log,
   [
    [ bless { type => 'foo' }, 'msg' ],
    [ bless { type => 'bar' }, 'msg' ],
    [ bless { type => 'bar' }, 'msg' ]
   ],
   "messages to rec1";

  is_deeply $rec2->log,
   [ [ bless { type => 'foo' }, 'msg' ], ],
   "messages to rec2";
}

# vim:ts=2:sw=2:et:ft=perl


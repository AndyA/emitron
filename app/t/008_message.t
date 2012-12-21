#!perl

use strict;
use warnings;
use Test::More tests => 9;

use Emitron::Message;

{
  ok my $msg = Emitron::Message->new( type => 'test', msg => {} ), 'new';
  isa_ok $msg, 'Emitron::Message';
  is $msg->type, 'test', 'type';

  ok my $msg2 = Emitron::Message->from_raw($msg), 'from_raw: clone';
  isa_ok $msg2, 'Emitron::Message';
  is $msg2->type, 'test', 'type';

  ok my $msg3 = Emitron::Message->from_raw(
    { type   => 'raw',
      msg    => {},
      source => 'raw',
      worker => $$
    }
   ),
   'from_raw: raw';

  isa_ok $msg3, 'Emitron::Message';
  is $msg3->type, 'raw', 'type';
}

# vim:ts=2:sw=2:et:ft=perl


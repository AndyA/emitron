#!perl

use strict;
use warnings;
use Test::More;

use ForkPipe;

{
  ok my $fp = ForkPipe->new, 'new';
  isa_ok $fp, 'ForkPipe';
}

done_testing();

# vim:ts=2:sw=2:et:ft=perl


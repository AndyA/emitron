#!perl

use strict;
use warnings;

use Emitron::App;
use Test::More;

{
  isa_ok em, 'Emitron::App';
}

done_testing();

# vim:ts=2:sw=2:et:ft=perl


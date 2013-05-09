#!/usr/bin/env perl

use strict;
use warnings;

my $exp = join ' || ', map { qq{system("perl $_")} } @ARGV;

print <<EOC;
#include <stdlib.h>

int main(void) {
  return $exp;
}
EOC

# vim:ts=2:sw=2:sts=2:et:ft=perl


#!/usr/bin/env perl

use strict;
use warnings;

use JSON;
use Path::Class;

use constant OUT => 'stash';

my $db = merge(OUT);
my $out = file OUT, 'db.json';
print { $out->openw } JSON->new->pretty->encode($db);

sub merge {
  my $dir = shift;
  [ map { JSON->new->decode( scalar file( $dir, $_ )->slurp ) }
     sort
     grep { /^r\d+\.json$/ } do {
      opendir my $dh, $dir or die "Can't read $dir: $!\n";
      readdir $dh;
     }
  ];
}

# vim:ts=2:sw=2:sts=2:et:ft=perl


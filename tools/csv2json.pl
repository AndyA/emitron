#!/usr/bin/env perl

use strict;
use warnings;

use JSON;
use Text::CSV_XS;

my $csv = Text::CSV_XS->new( { binary => 1, eol => $/ } );
my @lbl = ();
my @db  = ();
while ( my $row = $csv->getline(*ARGV) ) {
  my @f = map { trim($_) } @$row;
  if (@lbl) {
    my $rec = {};
    @{$rec}{@lbl} = @f;
    push @db, $rec;
  }
  else {
    @lbl = @f;
  }
}

print JSON->new->pretty->encode( \@db );

sub trim {
  my $s = shift;
  s/^\s+//, s/\s+$// for $s;
  return $s;
}

# vim:ts=2:sw=2:sts=2:et:ft=perl


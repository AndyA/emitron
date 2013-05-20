#!/usr/bin/env perl

use strict;
use warnings;

use JSON;
use Path::Class;
use Text::CSV_XS;

use constant PROXY => 'proxy';

my %HLS_PATH = (
  a => 'a/%s/a.m3u8',
  b => 'b/%s.m3u8',
);

my $index = [];
for my $src (@ARGV) {
  import( $index, file($src)->openr );
}

my $i2 = cook($index);

print JSON->new->pretty->canonical->encode($i2);

sub import {
  my ( $index, $fh ) = @_;
  my $csv = Text::CSV_XS->new
   or die "Cannot use CSV: " . Text::CSV_XS->error_diag();
  my @col = ();
  while ( my $row = $csv->getline($fh) ) {
    my @row = map trim($_), @$row;
    next unless grep length, @row;
    unless (@col) { @col = map nice_name($_), @row; next }
    my $rec = {};
    @{$rec}{@col} = @row;
    delete $rec->{''};
    push @$index, $rec;
  }

}

sub cook {
  my $idx = shift;
  my @ni  = ();
  for my $prog (@$idx) {
    my %np = %$prog;
    ( my $base = $np{file_name} ) =~ s/\.mxf$//;
    $np{media}{$_} = sprintf $HLS_PATH{$_}, $base for keys %HLS_PATH;
    push @ni, \%np;
  }
  return \@ni;
}

sub proxy_name {
  ( my $fn = shift ) =~ s/\.mxf$/.mov/i;
  return file( PROXY, $fn );
}

sub nice_name {
  my $s = shift;
  $s =~ s/\W+/_/g;
  return lc $s;
}

sub trim {
  my $s = shift;
  s/^\s+//, s/\s+$// for $s;
  return $s;
}

# vim:ts=2:sw=2:sts=2:et:ft=perl


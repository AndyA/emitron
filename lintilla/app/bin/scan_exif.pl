#!/usr/bin/env perl

use strict;
use warnings;

use Image::ExifTool qw( :Public );
use JSON;
use Data::Dumper;
use Path::Class;

use constant STASH => 'public/asset/elvis/stash.json';
use constant ASSET => 'public/asset/elvis/%s/%d.jpg';

my $stash = load_json(STASH);

my %got = ();

for my $id ( sort { $a <=> $b } keys %$stash ) {
  for my $set ( sort keys %{ $stash->{$id} } ) {
    my $rec = $stash->{$id}{$set};
    my $img = sprintf ASSET, $set, $id;
    unless ( -e $img ) {
      warn "$img not found\n";
      next;
    }
    print STDERR "$img\n";
    my $info = ImageInfo($img);
    $got{$_}++ for keys %$info;
  }
}

print JSON->new->canonical->pretty->encode( \%got );

# Strangely asymmetric application of utf8 seems to DRT. Shrug.

sub load_json { JSON->new->utf8->decode( scalar file( $_[0] )->slurp ) }

sub save_json {
  my $out = file( $_[0] );
  my $tmp = file("$out.tmp");
  $tmp->parent->mkpath;
  my $fh = $tmp->openw;
  $fh->binmode(':utf8');
  print $fh JSON->new->pretty->encode( $_[1] );
  rename "$tmp", "$out" or die "Can't rename $tmp as $out: $!\n";
}

# vim:ts=2:sw=2:sts=2:et:ft=perl


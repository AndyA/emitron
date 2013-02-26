#!/usr/bin/env perl

use strict;
use warnings;

use GD;
use Path::Class;

use constant QUALITY => 85;

$| = 1;

barcode($_) for @ARGV;

sub barcode {
  my $dir = dir $_[0];
  my $bc = file( $dir, "barcode.jpeg" );
  print "$dir\n";
  if ( -e "$bc" ) {
    print "  $bc exists\n";
    return;
  }
  my @img = sort grep { /\.jpe?g$/ } $dir->children;
  my ( $wrk, $sw, $ww, $w, $h );
  my $pos = 0;
  for my $img (@img) {
    my $in = GD::Image->new("$img");
    unless ($wrk) {
      ( $w, $h ) = $in->getBounds();
      my $slices = @img;
      $sw = int( $w / $slices + 2 );
      print "  slice width: $sw\n";
      $ww = $sw * $slices;
      print "  work image width: $ww\n";
      $wrk = GD::Image->new( $ww, $h, 1 );
    }
    print "\r  $img";
    $wrk->copyResampled( $in, $pos, 0, 0, 0, $sw, $h, $w, $h );
    $pos += $sw;
  }
  my $dst = GD::Image->new( $w, $h, 1 );
  $dst->copyResampled( $wrk, 0, 0, 0, 0, $ww, $h, $w, $h );

  print "\n  Writing $bc\n";
  print { $bc->openw } $dst->jpeg(QUALITY);
}

# vim:ts=2:sw=2:sts=2:et:ft=perl


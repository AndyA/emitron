#!/usr/bin/env perl

use strict;
use warnings;

use GD;
use Path::Class;

use constant QUALITY => 85;
use constant THUMB_W => 180;
use constant THUMB_H => 60;

$| = 1;

barcode($_) for @ARGV;

sub barcode {
  my $dir   = dir $_[0];
  my $raw   = file( $dir, "barcode-raw.jpeg" );
  my $bc    = file( $dir, "barcode.jpeg" );
  my $thumb = file( $dir, "barcode-thumb.jpeg" );
  return if -e "$bc" && -e "$raw" && -e "$thumb";
  print "$dir\n";
  my @img = sort grep { /\.jpe?g$/ } $dir->children;
  unless (@img) {
    print "  No images found\n";
    return;
  }
  my ( $wrk, $sw, $ww, $w, $h );
  my $pos = 0;
  for my $img (@img) {
    my $in = GD::Image->new("$img");
    unless ($wrk) {
      ( $w, $h ) = $in->getBounds();
      my $slices = @img;
      $sw = int( $w / $slices + 2 );
      $ww = $sw * $slices;
      while ( $ww > 32767 && $sw > 1 ) {
        $sw--;
        $ww = $sw * $slices;
      }
      print "  slice width: $sw\n";
      print "  work image width: $ww\n";
      $wrk = GD::Image->new( $ww, $h, 1 );
    }
    print "\r  $img";
    $wrk->copyResampled( $in, $pos, 0, 0, 0, $sw, $h, $w, $h );
    $pos += $sw;
  }
  my $dst = GD::Image->new( $w, $h, 1 );
  $dst->copyResampled( $wrk, 0, 0, 0, 0, $w, $h, $ww, $h );

  print "\n  Writing $bc\n";
  save_image( $dst, $bc );
  save_image( $wrk, $raw );
  my $tb = GD::Image->new( THUMB_W, THUMB_H, 1 );
  $tb->copyResampled( $wrk, 0, 0, 0, 0, THUMB_W, THUMB_H, $ww, $h );
  save_image( $tb, $thumb );
}

sub save_image {
  my ( $img, $name ) = @_;
  print { file($name)->openw } $img->jpeg(QUALITY);
}

# vim:ts=2:sw=2:sts=2:et:ft=perl


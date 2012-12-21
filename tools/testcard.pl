#!/usr/bin/env perl

use strict;
use warnings;

use GD;
use List::Util qw( min max );
use Path::Class;

use constant FPS  => 25;
use constant FONT => glob '~/Dropbox/Fonts/Envy\ Code\ R.ttf';

my $iterations = shift || 1;

$| = 1;

testcard(
  width      => 1024,
  height     => 576,
  frames     => 500,
  leadin     => 100,
  leadout    => 100,
  out        => 'testcard',
  template   => 'f%06d.jpeg',
  font       => FONT,
  fontsize   => 100,
  iterations => $iterations,
);

sub testcard {
  my %a = @_;

  my $out = dir( $a{out} );
  $out->mkpath;

  for my $frr ( 0 .. $a{frames} * $a{iterations} - 1 ) {
    my $tc = tc( $frr + 1 );
    my $fr = $frr % $a{frames};
    print "\r$tc";

    my $img = GD::Image->new( $a{width}, $a{height}, 1 );
    my $bg
     = $fr < $a{leadin} || $fr >= $a{frames} - $a{leadout}
     ? $img->colorAllocate( 255, 0, 0 )
     : $img->colorAllocate( 0,   0, 0 );
    my $fg = $img->colorAllocate( 255, 255, 255 );

    $img->filledRectangle( 0, 0, $a{width}, $a{height}, $bg );

    {
      my @ft = ( $fg, $a{font}, $a{fontsize}, 0, 0, 0, $tc );
      my ( $lx, $ty, $rx, $by ) = bbox( GD::Image->stringFT(@ft) );
      my $w = $rx - $lx;
      my $h = $by - $ty;
      $ft[-3] = ( $a{width} - $w ) / 2;
      $ft[-2] = ( $a{height} - $h ) / 2 + $h;
      $img->stringFT(@ft);
    }

    {
      my $scale = $a{frames} - $a{leadin} - $a{leadout};
      my $bw    = $a{width} / 2;
      my $pos
       = max( 0, min( $bw, $bw * ( $fr - $a{leadin} ) / $scale ) );

      for my $dy ( 30, $a{height} - 1 - 30 ) {
        $img->filledRectangle( 0, $dy - 10, $pos, $dy + 10, $fg );
        $img->filledRectangle( $a{width} - $pos,
          $dy - 10, $a{width}, $dy + 10, $fg );
      }
    }

    file( $out, sprintf $a{template}, $frr )->openw->print( $img->jpeg(90) );
  }
  print "\n";
}

sub bbox {
  my @bb = @_;
  return (
    min( @bb[0, 2, 4, 6] ),
    min( @bb[1, 3, 5, 7] ),
    max( @bb[0, 2, 4, 6] ),
    max( @bb[1, 3, 5, 7] ),
  );
}

sub tc {
  my $fr   = shift;
  my @div  = ( 24, 60, 60, FPS );
  my @part = ();
  while ( my $d = pop @div ) {
    unshift @part, $fr % $d;
    $fr = int( $fr / $d );
  }
  return sprintf join( ':', ('%02d') x @part ), @part;
}

# vim:ts=2:sw=2:sts=2:et:ft=perl


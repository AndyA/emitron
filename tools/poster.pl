#!/usr/bin/env perl

use feature ":5.10";

use strict;
use warnings;
use autodie;

use GD;
use Getopt::Long;
use List::Util qw( first min max sum );
use Path::Class;

my %O = (
  outdir => undef,
  size   => [],
  scan   => 5 * 60,
  skip   => 30,
  rate   => 1,
);

GetOptions(
  'outdir=s' => \$O{outdir},
  'size=s'   => $O{size},
  'scan=s'   => \$O{scan},
  'skip=s'   => \$O{skip},
  'rate=i'   => \$O{rate},
) or die "Bad syntax";

# Check sizes
with_size( sub { } );

for my $vid (@ARGV) {
  print "Extracting from $vid\n";
  my $outd = dir( $O{outdir} // file($vid)->parent );
  ( my $name = file($vid)->basename ) =~ s/\.[^.]*$//;

  my $full = file( $outd, 'full', "$name.jpg" );

  unless ( -e $full ) {
    my $workd = dir( $outd, $name );
    $workd->mkpath;
    my @cmd = (
      'ffmpeg',
      -ss => $O{skip},
      -t  => $O{scan},
      -i  => $vid,
      -r  => $O{rate},
      -f  => 'image2',
      file( $workd, '%08d.jpg' )
    );
    print "Extracting frames\n";
    system @cmd;
    my $best = choose($workd);
    die "No frame found" unless $best;
    $full->parent->mkpath;
    link $best, $full;
    $workd->rmtree;
  }

  with_size(
    sub {
      my ( $mw, $mh ) = @_;
      my $thumb = file( $outd, "${mw}x${mh}", "$name.jpg" );
      print "Generating $thumb\n";
      scale($full, $thumb, $mw, $mh);
    }
  );

}

sub with_size {
  my $cb = shift;
  for my $sz ( @{ $O{size} } ) {
    die "Bad size: $sz\n" unless $sz =~ /^(\d+)x(\d+)$/;
    $cb->( $1, $2 );
  }
}

sub choose {
  my $dir = shift;
  my @img = sort { $a->[1] <=> $b->[1] }
   map { [$_, -s $_] } dir($dir)->children;
  return choose_best(@img);    # TODO multiple algos.
}

sub choose_best {
  my @img  = @_;
  my $pick = int( @img * 3 / 4 );
  return $img[$pick][0];
}

sub fit {
  my ( $iw, $ih, $mw, $mh ) = @_;
  my $sc = min( $mw / $iw, $mh / $ih );
  return ( int( $iw * $sc ), int( $ih * $sc ) );
}

sub save {
  my ( $fn, $img, $quality ) = @_;
  $quality ||= 90;
  my $tmp = file("$fn.tmp");
  $tmp->parent->mkpath;
  my $of = $tmp->openw;
  $of->binmode;
  print $of $img->jpeg($quality);

  rename "$tmp", "$fn";
}

sub scale {
  my ( $in, $out, $mw, $mh ) = @_;

  my $img = GD::Image->new("$in");
  defined $img or die "Can't load $in";

  my ( $iw, $ih ) = $img->getBounds;
  my ( $ow, $oh ) = fit( $iw, $ih, $mw, $mh );
  if ( $iw != $ow || $ih != $oh ) {
    my $thb = GD::Image->new( $ow, $oh, 1 );
    $thb->copyResampled( $img, 0, 0, 0, 0, $ow, $oh, $iw, $ih );
    save( $out, $thb );
  }
  else {
    save( $out, $img );
  }

}

# vim:ts=2:sw=2:sts=2:et:ft=perl


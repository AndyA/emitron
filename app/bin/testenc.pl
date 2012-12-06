#!/usr/bin/env perl

use Moose;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Emitron::Media::Encoder;
use Path::Class;

my $CONFIG = [
  {
    name        => 'p30',
    destination => 'testenc/p30/f%08d.ts',
    profile     => {
      v => {
        bitrate => 304_000,
        rate    => 25,
        profile => 'baseline',
        level   => 3,
        width   => 400,
        height  => 224
      },
      a => {
        bitrate => 64_000,
        profile => 'aac_lc',
        rate    => 44_100,
      }
    },
  },
  {
    name        => 'p50',
    destination => 'testenc/p50/f%08d.ts',
    profile     => {
      v => {
        bitrate => 700_000,
        rate    => 25,
        profile => 'main',
        level   => 3,
        width   => 640,
        height  => 360
      },
      a => {
        bitrate => 96_000,
        profile => 'aac_lc',
        rate    => 44_100,
      }
    },
  }
];

my $TMP = 'testenc/tmp';
dir( $TMP )->mkpath;

my $DOG = "$FindBin::Bin/../../art/thespace-dog.png";

my $enc = Emitron::Media::Encoder->new(
  source  => 'rtsp://newstream.fenkle:5544/orac',
  config  => $CONFIG,
  burnin  => 1,
  dog     => $DOG,
  tmp_dir => $TMP
);

$enc->start;
sleep 60;
$enc->stop;

# vim:ts=2:sw=2:sts=2:et:ft=perl


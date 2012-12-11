#!perl

use Moose;

use Test::More;

use Emitron::Media::Encoder;

my $CONFIG = [
  {
    name        => 'p30',
    destination => '/tmp/p30/f%08d.ts',
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
    destination => '/tmp/p50/f%08d.ts',
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

{
  ok my $enc = Emitron::Media::Encoder->new(
    name   => 'test',
    source => 'rtsp://newstream.fenkle:5544/orac',
    config => $CONFIG,
    burnin => 1,
   ),
   'new';
  isa_ok $enc, 'Emitron::Media::Encoder';
  is $enc->programs->ffmpeg, 'ffmpeg', 'ffmpeg';
  is $enc->globals->aspect_ratio_str( ':' ), '16:9', 'aspect_ratio_str';
}

done_testing();

# vim:ts=2:sw=2:et:ft=perl


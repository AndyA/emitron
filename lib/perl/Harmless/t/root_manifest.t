#!perl

use strict;
use warnings;

use File::Temp;
use Harmless::M3U8;

use Test::Differences;
use Test::More;

{
  my $vpl = [
    { 'EXT_X_STREAM_INF' => {
        'PROGRAM_ID' => '1',
        'BANDWIDTH'  => '485192'
      },
      'uri' => 'segmenter-1.m3u8'
    },
    { 'EXT_X_STREAM_INF' => {
        'PROGRAM_ID' => '1',
        'BANDWIDTH'  => '924428'
      },
      'uri' => 'segmenter-2.m3u8'
    },
    { 'EXT_X_STREAM_INF' => {
        'PROGRAM_ID' => '1',
        'BANDWIDTH'  => '1656489'
      },
      'uri' => 'segmenter-3.m3u8'
    },
    { 'EXT_X_STREAM_INF' => {
        'PROGRAM_ID' => '1',
        'BANDWIDTH'  => '2319236'
      },
      'uri' => 'segmenter-4.m3u8'
    }
  ];

  my $tf = File::Temp->new;

  my $m3u8 = Harmless::M3U8->new;
  $m3u8->vpl($vpl);
  $m3u8->write($tf);

  my $m3u9 = Harmless::M3U8->new->read($tf);
  eq_or_diff $m3u9->vpl, $vpl, "vpl";
}

done_testing();

# vim:ts=2:sw=2:et:ft=perl


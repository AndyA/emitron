#!perl

use strict;
use warnings;

use Data::Dumper;
use Celestian::EvoStream::JSON qw( detox_json );

use Test::More tests => 1;

my $in = {
  'status' => 'SUCCESS',
  'data'   => {
    'push'   => [],
    'record' => [],
    'pull'   => [
      {
        'width'    => 0,
        'pageUrl'  => '',
        'configId' => 4,
        'ttl'      => 0,
        'isHls' => bless( do { \( my $o = 0 ) }, 'JSON::XS::Boolean' ),
        'rtcpDetectionInterval' => 10,
        'isPull' => bless( do { \( my $o = 1 ) }, 'JSON::XS::Boolean' ),
      },
    ],
  },
};

my $out = {
  'status' => 'SUCCESS',
  'data'   => {
    'push'   => [],
    'record' => [],
    'pull'   => [
      {
        'width'                 => 0,
        'pageUrl'               => '',
        'configId'              => 4,
        'ttl'                   => 0,
        'isHls'                 => 0,
        'rtcpDetectionInterval' => 10,
        'isPull'                => 1,
      },
    ],
  },
};

my $got = detox_json( $in );

is_deeply $got, $out, 'JSON detoxed' or diag Dumper( $got );

# vim:ts=2:sw=2:et:ft=perl


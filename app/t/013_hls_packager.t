#!perl

use Moose;

use Test::More;

use Emitron::Media::Packager::HLS;

my $CONFIG = [];

{
  ok my $pkg = Emitron::Media::Packager::HLS->new(
    name    => 'test',
    webroot => 'webroot/live/hls/test',
    config  => $CONFIG,
   ),
   'new';
  isa_ok $pkg, 'Emitron::Media::Packager::HLS';
}

done_testing();

# vim:ts=2:sw=2:et:ft=perl


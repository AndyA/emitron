#!/usr/bin/env perl

use strict;
use warnings;
use RTSP::Client;

my $client = RTSP::Client->new_from_uri(
  transport_protocol => 'RTP/AVP;multicast',
  uri                => 'rtsp://newstream.fenkle:5544/phool',
  debug              => 1,
  print_headers      => 1,
);

$client->open or die $!;

my $sdp                    = $client->describe;
my @allowed_public_methods = $client->options_public;

print "$sdp\n";
print "Allowed:\n";
print "  $_\n" for @allowed_public_methods;

$client->setup;
#$client->reset;

$client->play;
#$client->pause;

$client->teardown;

# vim:ts=2:sw=2:sts=2:et:ft=perl


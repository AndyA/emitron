package Emitron::Tool::Packager::HLS;

use Moose;

extends 'Emitron::Tool::Base';

=head1 NAME

Emitron::Tool::Packager::HLS - HLS Packager

=cut

my $CONFIG = [];

{
  ok my $pkg = Emitron::Media::Packager::HLS->new(
    webroot => 'webroot/live/hls/test',
    config  => $CONFIG,
   ),
   'new';
  isa_ok $pkg, 'Emitron::Media::Packager::HLS';
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

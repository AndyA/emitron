#!/usr/bin/env perl

use strict;
use warnings;

use lib qw( app/lib );

use Data::Dumper;
use NewStream::EvoStream;

#￼￼tream uri=rtsp://AddressOfStream keepAlive=1 localStreamname=livetest￼

use constant SOURCE => 'rtmp://zaphod-origin.ch.bbc.co.uk/live/inlet5';
use constant LOCAL  => 'bbclive';

my $evo = NewStream::EvoStream->new( host => 'localhost' );
purge_stream( $evo, LOCAL );
my $ps = $evo->pull_stream(
  keepAlive        => 1,
  localStreamName  => LOCAL,
  uri              => SOURCE,
  emulateUserAgent => 'flash',
);
print Dumper( $ps );

sub id_from_name {
  my ( $resp, $name ) = @_;
  return map { $_->{configId} }
   grep { $_->{localStreamName} eq $name } @{ $resp->{data}{pull} };
}

sub purge_stream {
  my ( $evo, $name ) = @_;
  my $cfg = $evo->list_pull_push_config;
  for my $id ( id_from_name( $cfg, $name ) ) {
    print "Purging $id\n";
    $evo->remove_pull_push_config( id => $id, removeHlsHdsFiles => 1 );
  }
}

# vim:ts=2:sw=2:sts=2:et:ft=perl


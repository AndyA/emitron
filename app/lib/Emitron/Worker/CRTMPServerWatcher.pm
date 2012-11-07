package Emitron::Worker::CRTMPServerWatcher;

use strict;
use warnings;

use Emitron::BackOff;
use Emitron::Logger;
use JSON;

use base qw( Emitron::Worker::Base );

use accessors::ro qw( uri );

=head1 NAME

Emitron::Worker::CRTMPServerWatcher - Poll crtmpserver

=cut

sub run {
  my $self = shift;

  my $prev = undef;
  my $srv = Emitron::CRTMPServer->new( uri => 'http://localhost:6502' );
  my $bo = Emitron::BackOff->new( base => 1, max => 10 );

  while () {
    my $streams = eval { $srv->api( 'listStreams' ) };
    if ( my $err = $@ ) {
      error $err;
      sleep $bo->bad;
    }
    elsif ( $streams ) {
      my $next = encode_json $streams;
      unless ( defined $prev && $prev eq $next ) {
        $self->post_message(
          model => {
            path => '$.ms.streams',
            data => $streams,
          }
        );
        $prev = $next;
      }
      sleep $bo->good;
    }
  }
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

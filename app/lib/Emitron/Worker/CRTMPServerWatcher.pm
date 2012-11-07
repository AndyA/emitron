package Emitron::Worker::CRTMPServerWatcher;

use strict;
use warnings;

use Emitron::BackOff;
use Emitron::Logger;
use JSON;

use base qw( Emitron::Worker::Base );

use accessors::ro qw( uri verb backoff );

=head1 NAME

Emitron::Worker::CRTMPServerWatcher - Poll crtmpserver

=cut

sub run {
  my $self = shift;

  my $prev = undef;
  my $srv = Emitron::CRTMPServer->new( uri => 'http://localhost:6502' );

  while () {
    my $streams = eval { $srv->api( $self->verb ) };
    if ( my $err = $@ ) {
      error $err;
      sleep $self->backoff->bad;
    }
    elsif ( $streams ) {
      my $next = encode_json $streams;
      unless ( defined $prev && $prev eq $next ) {
        $self->post_message(
          crtmpserver => {
            verb => $self->verb,
            data => $streams,
          }
        );
        $prev = $next;
      }
      sleep $self->backoff->good;
    }
  }
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

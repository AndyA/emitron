package Emitron::Worker::CRTMPServerWatcher;

use strict;
use warnings;

use Emitron::BackOff;
use Emitron::Logger;
use JSON;
use Time::HiRes qw( sleep );

use base qw( Emitron::Worker::Base );

use accessors::ro qw( event model uri backoff );

=head1 NAME

Emitron::Worker::CRTMPServerWatcher - Poll crtmpserver

=cut

sub run {
  my $self = shift;

  my $prev    = undef;
  my $srv     = Emitron::CRTMPServer->new( uri => $self->uri );
  my $backoff = Emitron::BackOff->new( base => 1, max => 10 );

  while () {
    my $streams = eval { $srv->api( 'listStreams' ) };
    if ( my $err = $@ ) {
      error $err;
      sleep $backoff->bad;
    }
    elsif ( $streams ) {
      my $next = encode_json $streams;
      unless ( defined $prev && $prev eq $next ) {
        $self->_handle_listStreams( $streams );
        $prev = $next;
      }
      sleep $backoff->good;
    }
  }
}

sub _handle_listStreams {
  my ( $self, $data ) = @_;

  # Quick and a little dirty
  $self->model->transaction(
    sub {
      my ( $model, $rev ) = @_;
      $model->{streams} = $self->_munge_streams( $data );
      debug "Model update: ", $model;
      return $model;
    }
  );
}

sub _munge_streams {
  my ( $self, $data ) = @_;
  my $out = {};
  for my $app ( keys %$data ) {
    my $by_type = $data->{$app}{streams} || {};
    for my $type ( keys %$by_type ) {
      my $by_name = $by_type->{$type};
      for my $name ( keys %$by_name ) {
        my $rec = $by_name->{$name};
        $rec->{preview} = $self->_preview_url( $name );
        $out->{$name}{$type}{$app} = $rec;
      }
    }
  }

  debug "Media server stream update: ", $data;

  return $out;
}

sub _preview_url {
  my ( $self, $name ) = @_;
  # TODO hardwired for now
  return 'rtmp://newstream.fenkle/live/' . $name;
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

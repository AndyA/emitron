package Emitron::App;

use strict;
use warnings;

use Data::Dumper;
use Emitron::BackOff;
use Emitron::CRTMPServer;
use Emitron::Logger;
use Emitron::Message;
use Emitron::Model::Watched;
use Emitron::Runner;
use Emitron::Worker;
use JSON;
use Time::HiRes qw( sleep );

use constant QUEUE => '/tmp/emitron.queue';
use constant MODEL => '/tmp/emitron.model';

=head1 NAME

Emitron::App - The Emitron app.

=cut

sub new {
  my $class = shift;
  return bless {@_}, $class;
}

sub run {
  my $self = shift;
  Emitron::Runner->new(
    workers    => $self->make_workers,
    post_event => $self->make_event_cleanup
  )->run;
}

sub make_workers {
  my $self = shift;
  my @w    = ();
  push @w, $self->make_event_watcher;
  push @w, $self->make_crtmpserver_watcher;
  push @w, $self->make_worker for 1 .. 3;
  return \@w;
}

sub queue {
  my $self = shift;
  return $self->{queue}
   ||= Emitron::Model::Watched->new( root => QUEUE )->init;
}

sub make_event_cleanup {
  my $self  = shift;
  my $queue = $self->queue;
  return sub {
    my $msg = shift;
    if ( $msg->source eq 'api' ) {
      $queue->remove( $msg->{cleanup} );
    }
  };
}

sub make_event_watcher {
  my $self  = shift;
  my $queue = $self->queue;
  my $first = $queue->earliest;
  my $rev   = defined $first ? $first - 1 : undef;
  my $ser   = 0;
  return sub {
    my ( undef, $wtr ) = @_;
    while () {
      my $nrev = $queue->revision;
      if ( defined $rev ) {
        for my $r ( $rev + 1 .. $nrev ) {
          my $msg = $queue->checkout( $r );
          Emitron::Message->new(
            message => $msg,
            source  => 'api',
            cleanup => $r
           )->send( $wtr )
           if defined $msg;
        }
      }
      $rev = $nrev;
      $ser = $queue->wait( $ser, 10 );
    }
  };
}

sub make_crtmpserver_watcher {
  my $self = shift;
  my $prev = undef;
  my $srv = Emitron::CRTMPServer->new( uri => 'http://localhost:6502' );
  my $bo = Emitron::BackOff->new( base => 1, max => 10 );
  return sub {
    my ( undef, $wtr ) = @_;
    while () {
      my $streams = eval { $srv->api( 'listStreams' ) };
      if ( my $err = $@ ) {
        error $err;
        sleep $bo->bad;
      }
      elsif ( $streams ) {
        my $next = encode_json $streams;
        unless ( defined $prev && $prev eq $next ) {
          Emitron::Message->new(
            model => {
              path => '$.ms.streams',
              data => $streams,
            }
          )->send( $wtr );
          $prev = $next;
        }
        sleep $bo->good;
      }
    }
  };
}

sub make_worker {
  my $self = shift;
  return sub {
    my ( $get, $wtr ) = @_;
    while ( my $msg = $get->() ) {
      info 'Got message, type: ', $msg->type, ', source: ',
       $msg->source, ', msg: ', $msg->msg;
    }
  };
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

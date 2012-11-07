package Emitron::App;

use strict;
use warnings;

use Data::Dumper;
use Emitron::CRTMPServer;
use Emitron::Logger;
use Emitron::Message;
use Emitron::Model::Watched;
use Emitron::Runner;
use Emitron::Worker::Base;
use Emitron::Worker::Drone;
use Emitron::Worker::EventWatcher;
use Emitron::Worker::CRTMPServerWatcher;
use Emitron::Worker;
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
  push @w, Emitron::Worker::EventWatcher->new( queue => $self->queue );
  push @w,
   Emitron::Worker::CRTMPServerWatcher->new(
    uri => 'http://localhost:6502' );
  for ( 1 .. 3 ) {
    push @w, Emitron::Worker::Drone->new;
  }
  return \@w;
}

sub queue {
  my $self = shift;
  return $self->{queue}
   ||= Emitron::Model::Watched->new( root => QUEUE )->init;
}

# TODO this shouldn't be here.

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

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

package Emitron::App;

use Moose;

use Data::Dumper;
use Emitron::CRTMPServer;
use Emitron::Config;
use Emitron::Core;
use Emitron::Logger;
use Emitron::Message;
use Emitron::MessageDespatcher;
use Emitron::Model::Watched;
use Emitron::Runner;
use Emitron::Worker::Base;
use Emitron::Worker::CRTMPServerWatcher;
use Emitron::Worker::Drone;
use Emitron::Worker::EventWatcher;
use Emitron::Worker::ModelWatcher;
use Emitron::Worker;
use Time::HiRes qw( sleep );

use constant QUEUE => '/tmp/emitron.queue';
use constant MODEL => '/tmp/emitron.model';
use constant EVENT => '/tmp/emitron.event';

=head1 NAME

Emitron::App - The Emitron app.

=cut

sub run {
  my $self = shift;
  Emitron::Runner->new(
    workers    => $self->make_workers( $self->make_handlers ),
    post_event => $self->make_event_cleanup
  )->run;
}

sub make_handlers {
  my $self = shift;
  return ();
}

sub make_workers {
  my ( $self, @handlers ) = @_;
  my @w = ();

  my @default = (
    event => $self->event,
    core  => $self->core,
  );

  push @w,
   Emitron::Worker::EventWatcher->new( @default,
    queue => $self->queue );

  push @w,
   Emitron::Worker::CRTMPServerWatcher->new(
    @default,
    model => $self->model,
    uri   => 'http://localhost:6502'
   );

  push @w,
   Emitron::Worker::ModelWatcher->new( @default,
    model => $self->model );

  my $desp = Emitron::MessageDespatcher->new;
  $_->subscribe( $desp ) for @handlers;

  for ( 1 .. 5 ) {
    push @w,
     Emitron::Worker::Drone->new( @default, despatcher => $desp );
  }
  return \@w;
}

sub model {
  my $self = shift;
  return $self->{model}
   ||= Emitron::Model::Watched->new( root => MODEL, prune => 50 )
   ->init( Emitron::Config->config );
}

sub queue {
  my $self = shift;
  return $self->{queue}
   ||= Emitron::Model::Watched->new( root => QUEUE )->init;
}

sub event {
  my $self = shift;
  return $self->{event}
   ||= Emitron::Model::Watched->new( root => EVENT, prune => 50 )->init;
}

sub core {
  my $self = shift;
  return $self->{core} ||= Emitron::Core->new;
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

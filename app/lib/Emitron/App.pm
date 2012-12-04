package Emitron::App;

use Moose;

use Data::Dumper;
use Data::JSONTrigger;
use Emitron::CRTMPServer;
use Emitron::Config;
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

has root => ( isa => 'Str', is => 'ro', default => '/tmp/emitron' );
has in_child => (
  isa     => 'Bool',
  is      => 'rw',
  default => 0,
);

has model => (
  isa     => 'Emitron::Model::Watched',
  is      => 'ro',
  lazy    => 1,
  default => sub {
    Emitron::Model::Watched->new( root => MODEL, prune => 50 )
     ->init( Emitron::Config->config );
  }
);

has queue => (
  isa     => 'Emitron::Model::Watched',
  is      => 'ro',
  lazy    => 1,
  default => sub {
    Emitron::Model::Watched->new( root => QUEUE )->init;
  }
);

has event => (
  isa     => 'Emitron::Model::Watched',
  is      => 'ro',
  lazy    => 1,
  default => sub {
    Emitron::Model::Watched->new( root => EVENT, prune => 50 )->init;
  }
);

has _despatcher => (
  isa     => 'Emitron::MessageDespatcher',
  is      => 'ro',
  lazy    => 1,
  default => sub { Emitron::MessageDespatcher->new }
);

has _watcher => (
  isa     => 'Emitron::Worker::ModelWatcher',
  is      => 'ro',
  lazy    => 1,
  default => sub {
    my $self = shift;
    Emitron::Worker::ModelWatcher->new(
      event => $self->event,
      model => $self->model
    );
  }
);

has _trigger => (
  isa     => 'Data::JSONTrigger',
  is      => 'ro',
  lazy    => 1,
  default => sub { Data::JSONTrigger->new }
);

=head1 NAME

Emitron::App - The Emitron app.

=cut

{
  my ( $EMITRON );

  sub import {
    my $class = shift;
    $EMITRON ||= $class->new( @_ );
    {
      my $pkg = caller;
      no strict 'refs';
      *{"${pkg}::em"} = sub { $EMITRON };
    }
  }

  # Also available as a class method
  sub em { $EMITRON }
}

sub run {
  my $self = shift;
  Emitron::Runner->new(
    workers => $self->make_workers,
    cleanup => $self->make_event_cleanup
  )->run;
}

sub make_workers {
  my ( $self ) = @_;
  my @w = ();

  my @default = ( event => $self->event, );

  push @w,
   Emitron::Worker::EventWatcher->new( @default,
    queue => $self->queue );

  push @w,
   Emitron::Worker::CRTMPServerWatcher->new(
    @default,
    model => $self->model,
    uri   => 'http://localhost:6502'
   );

  push @w, $self->_watcher;

  my $desp = Emitron::MessageDespatcher->new;

  for ( 1 .. 5 ) {
    push @w,
     Emitron::Worker::Drone->new( @default, despatcher => $desp );
  }
  return \@w;
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

sub _wrap_handler {
  my ( $self, $handler ) = @_;
  return $handler;
}

sub _on {
  my ( $self, $name, $handler, $group ) = @_;
  if ( UNIVERSAL::can( $name, 'isa' ) && $name->isa( 'IO::Handle' ) ) {
    # Register handle to select on
    return;
  }
  if ( $name =~ /^\$/ ) {
    # JSONPath to trigger on
    if ( $self->in_child ) {
      $self->_trigger->on( $name, $self->_wrap_handler( $handler ) );
    }
    else {
      $self->_despatcher->on( $self->_watcher->listen( $name ),
        $self->_wrap_handler( $handler ), $group );
    }
    return;
  }
  $self->_despatcher->on( $name, $self->_wrap_handler( $handler ),
    $group );
}

sub on {
  my $self = shift;
  my $name = shift;
  for my $n ( 'ARRAY' eq ref $name ? @$name : $name ) {
    $self->_on( $n, @_ );
  }
  $self;
}

sub off {
  my ( $self, %like ) = @_;
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

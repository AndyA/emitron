package Emitron::App;

use Moose;

use Data::Dumper;
use Data::JSONTrigger;
use Emitron::CRTMPServer;
use Emitron::Config;
use Emitron::Context;
use Emitron::Logger;
use Emitron::Message;
use Emitron::MessageDespatcher;
use Emitron::Model::Watched;
use Emitron::Runner;
use Emitron::Worker::Base;
use Emitron::Worker::CRTMPServerWatcher;
use Emitron::Worker::EventWatcher;
use Emitron::Worker::ModelWatcher;
use Emitron::Worker::Script;
use Emitron::Worker;
use Time::HiRes qw( sleep );

has root => ( isa => 'Str', is => 'ro', default => '/tmp/emitron' );
has in_child => (
  isa     => 'Bool',
  is      => 'rw',
  default => 0,
);

has _context => (
  isa     => 'Emitron::Context',
  is      => 'ro',
  lazy    => 1,
  default => sub { Emitron::Context->new },
  handles => [ 'model', 'queue', 'event', 'despatcher' ]
);

has _watcher => (
  isa     => 'Emitron::Worker::ModelWatcher',
  is      => 'ro',
  lazy    => 1,
  default => sub {
    my $self = shift;
    Emitron::Worker::ModelWatcher->new;
  }
);

has _trigger => (
  isa     => 'Data::JSONTrigger',
  is      => 'ro',
  lazy    => 1,
  default => sub { Data::JSONTrigger->new }
);

has _listener => (
  isa     => 'Emitron::Listener',
  is      => 'ro',
  lazy    => 1,
  default => sub { Emitron::Listener->new },
  handles => {
    peek            => 'peek',
    poll            => 'poll',
    add_listener    => 'add',
    remove_listener => 'remove'
  }
);

has _revision => ( isa => 'Num', is => 'rw' );

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
    cleanup => $self->_make_cleanup
  )->run;
}

sub make_workers {
  my ( $self ) = @_;
  my @w = ();

  #  push @w, Emitron::Worker::EventWatcher->new;

  push @w,
   Emitron::Worker::CRTMPServerWatcher->new(
    uri => 'http://localhost:6502' );

  push @w, $self->_watcher;

  for ( 1 .. 5 ) {
    push @w, Emitron::Worker::Script->new;
  }

  return \@w;
}

# TODO this shouldn't be here.

sub _make_cleanup {
  my $self  = shift;
  my $queue = $self->queue;
  return sub {
    my $msg = shift;
    if ( $msg->source eq 'api' ) {
      $queue->remove( $msg->{cleanup} );
    }
  };
}

our $UID;

sub uid { $UID }

sub _make_uid { 'session.' . ++( shift->{_uid} ) }

sub _wrap_handler {
  my ( $self, $handler ) = @_;
  my $uid = $UID;
  return sub {
    local $UID = $uid || $self->_make_uid;
    debug "Running handler in $UID";
    $handler->( @_ );
  };
}

sub handle_events {
  my $self  = shift;
  my $event = $self->event;
  my $rev   = $event->revision;
  $self->add_listener(
    $event->fileno,
    sub {
      my $fn = shift;
      my $nrev = $event->wait( $rev, 10 );
      for my $r ( $rev + 1 .. $nrev ) {
        my $ev = $event->checkout( $r );
        $self->despatcher->despatch(
          Emitron::Message->from_raw( $ev ) );
      }
      $rev = $nrev;
    }
  );
}

sub _add_model_to_listener {
  my $self  = shift;
  my $model = $self->model;
  my $trig  = $self->_trigger;
  $trig->sneak( $model->checkout( $self->_revision ) );
  debug "Starting model listener for rev ", $self->_revision;
  $self->add_listener(
    $model->fileno,
    sub {
      my $fn = shift;
      my $nrev = $model->wait( $self->_revision, 10000 );
      if ( $nrev ne $self->_revision ) {
        $self->_revision( $nrev );
        $trig->data( $model->checkout( $nrev ) );
      }
    }
  );
}

sub _remove_model_from_listener {
  my $self = shift;
  debug "Stopping model listener for rev ", $self->_revision;
  $self->remove_listener( $self->model->fileno );
}

sub _on_path {
  my $self = shift;
  my $trig = $self->_trigger;
  $self->_add_model_to_listener unless $trig->has_trigger;
  $trig->on( @_ );
}

sub _off_path {
  my ( $self, %like ) = @_;
  my $trig = $self->_trigger;
  $trig->off( %like );
  $self->_remove_model_from_listener unless $trig->has_trigger;
}

sub _on_path_msg {
  my ( $self, $name, $handler, $group ) = @_;
  $self->despatcher->on(
    $self->_watcher->listen( $name ),
    sub {
      my $msg = shift;
      my ( $rev, @args ) = @{ $msg->msg };
      $self->_revision( $rev );
      $handler->( @args );
    },
    $group
  );
}

sub _on {
  my ( $self, $name, $hh, $group ) = @_;
  if ( UNIVERSAL::can( $name, 'isa' ) && $name->isa( 'IO::Handle' ) ) {
    # Register handle to select on
    die;
    return;
  }
  if ( $name =~ /^[-\*\+\$]/ ) {
    # JSONPath to trigger on
    return $self->in_child
     ? $self->_on_path( $name, $hh, $group )
     : $self->_on_path_msg( $name, $hh, $group );
  }
  $self->despatcher->on( $name, $hh, $group );
}

sub on {
  my ( $self, $name, $handler, $group ) = @_;
  $group = uid unless defined $group;
  my $hh = $self->_wrap_handler( $handler );
  for my $n ( 'ARRAY' eq ref $name ? @$name : $name ) {
    $self->_on( $n, $hh, $group );
  }
  $self;
}

sub off {
  my ( $self, %like ) = @_;

  if ( exists $like{path} ) {
    $self->_off_path( %like );
  }
  elsif ( exists $like{name} ) {
    $self->despatcher->off( %like );
  }
  else {
    $self->_off_path( %like );
    $self->despatcher->off( %like );
  }
}

sub off_all {
  my $self = shift;
  if ( $UID ) {
    debug "Removing handlers for $UID";
    $self->off( group => $UID );
    undef $UID;
  }
  else {
    warning "off_all called outside handler context";
  }
}

sub post_event {
  my ( $self, %args ) = @_;
  return $self->event->commit(
    {
      source => 'event',
      worker => $$,
      ts     => time,
      %args
    }
  );
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

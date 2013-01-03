package Emitron::App;

use Moose;

use Data::JSONPath;
use Data::JSONTrigger;
use Data::JSONVisitor;
use Emitron::Config;
use Emitron::Context;
use Emitron::Logger;
use Emitron::Message;
use Emitron::Worker::Base;
use Emitron::Worker::CRTMPServerWatcher;
use Emitron::Worker::EventWatcher;
use Emitron::Worker::ModelWatcher;
use Emitron::Worker::Script;
use Emitron::Worker::Tickler;
use ForkPipe::Muxer;
use ForkPipe;
use Path::Class;
use Time::HiRes qw( sleep time );

has root => ( isa => 'Str', is => 'ro', default => '/tmp/emitron' );

has worker => (
  isa     => 'Emitron::Worker::Base',
  is      => 'rw',
  handles => ['post_message']
);

has _context => (
  isa     => 'Emitron::Context',
  is      => 'ro',
  lazy    => 1,
  default => sub { Emitron::Context->new( root => shift->root ) },
  handles => ['model', 'queue', 'event', 'despatcher']
);

has _watcher => (
  isa     => 'Emitron::Worker::ModelWatcher',
  is      => 'ro',
  lazy    => 1,
  default => sub { Emitron::Worker::ModelWatcher->new }
);

has _trigger => (
  isa     => 'Data::JSONTrigger',
  is      => 'ro',
  lazy    => 1,
  default => sub {
    my $self = shift;
    my $trig = Data::JSONTrigger->new;
    $trig->sneak( $self->model->checkout( $self->_revision ) );
    return $trig;
  }
);

has _revision => (
  isa     => 'Num',
  is      => 'rw',
  lazy    => 1,
  default => sub { shift->model->revision }
);

has _muxer => (
  isa      => 'ForkPipe::Muxer',
  is       => 'rw',
  required => 1,
  lazy     => 1,
  default  => sub { ForkPipe::Muxer->new },
);

has _forkpipe => (
  isa => 'ForkPipe',
  is  => 'rw',
);

has _delegate => (
  isa     => 'ForkPipe|ForkPipe::Muxer',
  is      => 'rw',
  handles => ['send', 'peek', 'poll', 'state'],
);

=head1 NAME

Emitron::App - The Emitron app.

=cut

{
  my ($EMITRON);

  sub import {
    my $class = shift;
    $EMITRON ||= $class->new(@_);
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

  my $mux = $self->_muxer;

  for my $ww ( $self->make_workers ) {
    my $fp = ForkPipe->new( $mux->context );
    $mux->add($fp);
    $fp->spawn(
      sub {
        $self->_forkpipe($fp);
        $self->_delegate($fp);
        $self->worker($ww);
        $ww->run($fp);
      }
    );
  }

  $self->_delegate($mux);

  $mux->on(
    msg => sub {
      my $msg = shift;
      debug "received: ", $msg;
      $self->send($msg) if defined $msg;
    }
  );

  $mux->on(
    child => sub {
      confess "Worker died!\n";
    }
  );

  while () {
    info "WATCHDOG: ", $self->_worker_info;
    $mux->poll(10);
  }
}

sub _worker_info {
  my $self = shift;
  my @desc = ();
  for my $fp ( $self->_muxer->workers ) {
    push @desc, sprintf "%d (%s)", $fp->other_pid, $fp->state;
  }
  return join ', ', @desc;
}

sub make_workers {
  my ($self) = @_;
  my @w = ();

  #  push @w, Emitron::Worker::EventWatcher->new;

  push @w, (
    Emitron::Worker::CRTMPServerWatcher->new(
      uri => $self->uri('crtmpserver')
    ),
    #    Emitron::Worker::Tickler->new,
    $self->_watcher
  );

  for ( 1 .. 5 ) {
    push @w, Emitron::Worker::Script->new;
  }

  return @w;
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
    $handler->(@_);
  };
}

sub add_listener {
  my ( $self, $fn, $cb ) = @_;
  $self->_muxer->listener->add( $fn, $cb );
}

sub remove_listener {
  my ( $self, $fn ) = @_;
  $self->_muxer->listener->remove($fn);
}

sub handle_events {
  my $self  = shift;
  my $event = $self->event;
  # FIXME sometimes rev is undef at startup. Race?
  my $rev = $event->revision;
  $self->add_listener(
    $event->fileno,
    sub {
      my $fn   = shift;
      my $nrev = $event->poll;
      for my $r ( $rev + 1 .. $nrev ) {
        my $ev = $event->checkout($r);
        $self->despatcher->despatch( Emitron::Message->from_raw($ev) );
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
      my $fn   = shift;
      my $nrev = $model->poll;
      if ( $nrev ne $self->_revision ) {
        $self->_revision($nrev);
        $trig->data( $model->checkout($nrev) );
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
  $trig->on(@_);
}

sub _off_path {
  my ( $self, %like ) = @_;
  my $trig = $self->_trigger;
  $trig->off(%like);
  $self->_remove_model_from_listener unless $trig->has_trigger;
}

sub _on_path_msg {
  my ( $self, $name, $handler, $group ) = @_;
  $self->despatcher->on(
    $self->_watcher->listen($name),
    sub {
      my $msg = shift;
      my ( $rev, @args ) = @{ $msg->msg };
      if ( defined $rev ) {
        $self->_revision($rev);
        $handler->(@args);
      }
      else {
        error "Received model update message with no revision: ", $msg;
      }
    },
    $group
  );
}

sub _on {
  my ( $self, $name, $hh, $group ) = @_;
  if ( $name =~ /^[-\*\+\$]/ ) {
    # JSONPath
    return $self->worker
     ? $self->_on_path( $name, $hh, $group )
     : $self->_on_path_msg( $name, $hh, $group );
  }
  # Regular event
  $self->despatcher->on( $name, $hh, $group );
}

sub on {
  my ( $self, $name, $handler, $group ) = @_;
  $group = uid unless defined $group;
  debug "on '$name', group: ", $group;
  my $hh = $self->_wrap_handler($handler);
  for my $n ( 'ARRAY' eq ref $name ? @$name : $name ) {
    $self->_on( $n, $hh, $group );
  }
  $self;
}

sub off {
  my ( $self, %like ) = @_;

  if ( exists $like{path} ) {
    $self->_off_path(%like);
  }
  elsif ( exists $like{name} ) {
    $self->despatcher->off(%like);
  }
  else {
    $self->_off_path(%like);
    $self->despatcher->off(%like);
  }
}

sub off_all {
  my $self = shift;
  if ($UID) {
    debug "Removing handlers for $UID";
    $self->off( group => $UID );
  }
  else {
    warning "off_all called outside handler context";
  }
}

sub post_event {
  my ( $self, %args ) = @_;
  return $self->event->commit(
    { source => 'event',
      worker => $$,
      ts     => time,
      %args
    }
  );
}

sub cfg {
  my ( $self, $path, $cb ) = @_;
  my $v;
  $cb ||= sub { $v = shift };
  my $jp = Data::JSONPath->upgrade($path);
  Data::JSONVisitor->new( $self->_trigger->data->{config} )->each(
    $jp,
    sub {
      my ( $p, $v ) = @_;
      my @arg = @{ $jp->capture($p) };
      $cb->( $v, @arg );
    }
  );
  return $v;
}

sub uri {
  my ( $self, $base, @args ) = @_;
  my $uri = $self->cfg("\$.uri.$base");
  die "No uri defined for $base" unless defined $uri;
  return sprintf $uri, @args;
}

sub work_dir {
  my ( $self, @args ) = @_;
  my $nm = join '.', 'job', @args, $$, sprintf '%.3f', time;
  my $dir = dir( $self->cfg('$.paths.tmp'), $nm );
  $dir->mkpath;
  return "$dir";
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

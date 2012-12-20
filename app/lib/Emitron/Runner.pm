package Emitron::Runner;

use Moose;

use Carp qw( croak );
use Emitron::Logger;
use Emitron::Message;
use Emitron::Worker;
use IO::Handle;
use IO::Select;
use POSIX ":sys_wait_h";
use Time::HiRes qw( sleep );

=head1 NAME

Emitron::Runner - App core

=cut

has cleanup => (
  is      => 'ro',
  default => sub {
    sub { }
  }
);

has _rds => (
  isa     => 'IO::Select',
  is      => 'ro',
  default => sub { IO::Select->new }
);

has _active => (
  isa     => 'HashRef',
  is      => 'ro',
  default => sub { {} }
);

has _workers => (
  traits   => ['Array'],
  isa      => 'ArrayRef[Emitron::Worker::Base]',
  is       => 'ro',
  default  => sub { [] },
  init_arg => 'workers',
  handles  => {
    _w_put   => 'push',
    _w_avail => 'count',
    _w_get   => 'shift',
  },
);

has _mq => (
  traits  => ['Array'],
  isa     => 'ArrayRef[Emitron::Message]',
  is      => 'ro',
  default => sub { [] },
  handles => {
    enqueue  => 'push',
    _requeue => 'unshift',
    _m_avail => 'count',
    _m_get   => 'shift',
  },
);

sub run {
  my $self   = shift;
  my $active = $self->_active;
  my $rds    = $self->_rds;

  while () {
    while ( $self->_w_avail ) {
      my $handler = $self->_w_get;
      debug "New worker: ", ref $handler;
      my $wrk = Emitron::Worker->new( worker => $handler );
      $active->{ $wrk->pid } = {
        handler => $handler,
        wrk     => $wrk,
      };
      $rds->add( [ $wrk->reader, $wrk->pid ] );
    }

    my @rdy = $rds->can_read( 60 );

    for my $rd ( @rdy ) {
      my $ar = $active->{ $rd->[1] };
      die unless defined $ar;
      my $wrk = $ar->{wrk};
      my $msg = Emitron::Message->recv( $wrk->reader );
      #      debug "Got message: ", $msg;
      unless ( defined $msg ) {
        $self->recycle( $wrk->pid );
        next;
      }

      if ( $msg->type eq 'signal.state' ) {
        $wrk->signal( $msg );
        if ( $wrk->is_ready && defined( my $m = delete $ar->{msg} ) ) {
          $self->cleanup->( $m );
        }
      }
      else {
        #        debug "Sending message: ", $msg;
        $self->enqueue( $msg );
      }
    }

    info 'Worker status: ',
     join( ', ',
      map { sprintf "%s: %s", $_->pid, $_->state }
      sort { $a->pid <=> $b->pid } map { $_->{wrk} } values %$active );

    my @ready = grep { $_->{wrk}->is_ready } values %$active;
    while ( @ready && $self->_m_avail ) {
      my $msg = $self->_m_get;
      my $ar  = shift @ready;
      $ar->{msg} = $msg;
      debug "Delivering ", $msg->type, " to ", $ar->{wrk}{pid};
      $ar->{wrk}->send( $msg );
    }

    while () {
      my $pid = waitpid -1, WNOHANG;
      last unless defined $pid && $pid > 0;
      $self->recycle( $pid );
    }
  }
}

sub recycle {
  my ( $self, $pid ) = @_;
  info "Recyling $pid";
  if ( my $ar = delete $self->_active->{$pid} ) {
    $self->_rds->remove( $ar->{wrk}->reader );
    debug "Regenerating ", ref $ar->{handler};
    $self->_w_put( $ar->{handler} );
    if ( my $msg = delete $ar->{msg} ) {
      $self->_requeue( $msg );
    }
  }
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

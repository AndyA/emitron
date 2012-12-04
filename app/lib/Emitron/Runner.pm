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

has [ '_workers', '_mq' ] => (
  isa      => 'ArrayRef',
  is       => 'ro',
  default  => sub { [] },
  init_arg => 'workers'
);

sub enqueue {
  my ( $self, $msg ) = @_;
  push @{ $self->_mq }, $msg;
}

sub run {
  my $self    = shift;
  my $active  = $self->_active;
  my $mq      = $self->_mq;
  my $rds     = $self->_rds;
  my $workers = $self->_workers;

  while () {
    while ( @$workers ) {
      my $handler = shift @$workers;
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
        $self->enqueue( $msg );
      }
    }

    info 'Worker status: ',
     join( ', ',
      map { sprintf "%s: %s", $_->pid, $_->state }
      sort { $a->pid <=> $b->pid } map { $_->{wrk} } values %$active );

    my @ready = grep { $_->{wrk}->is_ready } values %$active;
    while ( @ready && @$mq ) {
      my $msg = shift @$mq;
      my $ar  = shift @ready;
      $ar->{msg} = $msg;
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
  if ( my $ar = delete $self->_active->{$pid} ) {
    $self->_rds->remove( $ar->{wrk}->reader );
    push @{ $self->_workers }, $ar->{handler};
    if ( my $msg = delete $ar->{msg} ) {
      unshift @{ $self->_mq }, $msg;
    }
  }
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

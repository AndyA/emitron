package Emitron::Runner;

use strict;
use warnings;

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

use accessors::ro qw( post_event );

sub new {
  my $class = shift;
  return bless {
    rds        => IO::Select->new,
    active     => {},
    workers    => [],
    mq         => [],
    post_event => sub { },
    @_
  }, $class;
}

sub enqueue {
  my ( $self, $msg ) = @_;
  push @{ $self->{mq} }, $msg;
}

sub run {
  my $self    = shift;
  my $active  = $self->{active};
  my $mq      = $self->{mq};
  my $rds     = $self->{rds};
  my $workers = $self->{workers};

  while () {
    while ( @$workers ) {
      my $handler = shift @$workers;
      my $wrk     = Emitron::Worker->new( $handler );
      $active->{ $wrk->pid } = {
        handler => $handler,
        wrk     => $wrk,
      };
      $rds->add( [ $wrk->reader, $wrk->pid ] );
    }

    my @rdy = $rds->can_read( 10 );

    for my $rd ( @rdy ) {
      my $ar = $active->{ $rd->[1] };
      die unless defined $ar;
      my $wrk = $ar->{wrk};
      my $msg = Emitron::Message->recv( $wrk->reader );
      unless ( defined $msg ) {
        $self->recycle( $wrk->pid );
        next;
      }

      if ( $msg->type eq 'signal' ) {
        $wrk->signal( $msg );
        if ( $wrk->is_ready && defined( my $m = delete $ar->{msg} ) ) {
          $self->{post_event}( $m );
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
  if ( my $ar = delete $self->{active}{$pid} ) {
    $self->{rds}->remove( $ar->{wrk}->reader );
    push @{ $self->{workers} }, $ar->{handler};
    if ( my $msg = delete $ar->{msg} ) {
      unshift @{ $self->{mq} }, $msg;
    }
  }
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

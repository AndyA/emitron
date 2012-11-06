package Emitron::Runner;

use strict;
use warnings;

use Carp qw( croak );
use Emitron::Message;
use Emitron::Worker;
use IO::Handle;
use IO::Select;
use POSIX ":sys_wait_h";
use Time::HiRes qw( sleep );

=head1 NAME

Emitron::Runner - App core

=cut

use accessors::ro qw( workers );

sub new {
  my $class = shift;
  return bless {
    rds     => IO::Select->new,
    active  => {},
    curmsg  => {},
    workers => 10,
    mq      => [],
    @_
  }, $class;
}

sub enqueue {
  my ( $self, $msg ) = @_;
  push @{ $self->{mq} }, $msg;
}

sub run {
  my $self   = shift;
  my $active = $self->{active};
  my $curmsg = $self->{curmsg};
  my $mq     = $self->{mq};
  my $rds    = $self->{rds};

  while () {
    while ( keys %$active < $self->workers ) {
      my $ttl = int( rand( 20 ) );
      my $wrk = Emitron::Worker->new(
        sub {
          my ( $msg, $wtr ) = @_;
          die if --$ttl <= 0;
          sleep rand() * 3;
          my $data = $msg->msg;
          $data->{touched}++;
          print "[$$] Processed $data->{id} ($data->{touched})\n";
          Emitron::Message->new( message => $data )->send( $wtr );
        }
      );
      $active->{ $wrk->pid } = $wrk;
      print "New worker ", $wrk->pid, "\n";
      $rds->add( [ $wrk->reader, $wrk->pid ] );
    }

    my @rdy = $rds->can_read( 10 );

    for my $rd ( @rdy ) {
      my $wrk = $active->{ $rd->[1] };
      die unless defined $wrk;
      my $msg = Emitron::Message->recv( $wrk->reader );
      next unless defined $msg;    # TODO

      if ( $msg->type eq 'signal' ) {
        $wrk->signal( $msg );
        delete $curmsg->{ $wrk->pid } if $wrk->is_ready;
      }
      else {
        $self->enqueue( $msg );
      }
    }

    my @active = sort { $a->pid <=> $b->pid } values %$active;
    print
     join( ', ', map { sprintf "%s: %s", $_->pid, $_->state } @active ),
     "\n";

    my @ready = grep { $_->is_ready } values %$active;
    while ( @ready && @$mq ) {
      my $msg = shift @$mq;
      my $wrk = shift @ready;
      $curmsg->{ $wrk->pid } = $msg;
      $wrk->send( $msg );
    }

    while () {
      my $pid = waitpid -1, WNOHANG;
      last unless defined $pid && $pid > 0;
      print "Reaping $pid\n";
      if ( my $wrk = delete $active->{$pid} ) {
        $rds->remove( $wrk->reader );
        if ( my $msg = delete $curmsg->{$pid} ) {
          unshift @$mq, $msg;
        }
      }
    }
  }
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

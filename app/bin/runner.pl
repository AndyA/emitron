#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Carp qw( croak );
use Config::Tiny;
use Data::Dumper;
use Data::Hexdumper;
use Emitron::Message;
use Emitron::Worker;
use IO::Handle;
use IO::Select;
use POSIX ":sys_wait_h";
use Time::HiRes qw( sleep );

use constant WORKERS => 5;

run();

sub run {
  my $rds    = IO::Select->new;
  my %active = ();
  my @mq     = ();
  for ( 1 .. 10 ) {
    push @mq,
     Emitron::Message->new( message => { id => $_, touched => 0 } );
  }

  while () {
    while ( keys %active < WORKERS ) {
      print "Creating worker\n";
      my $wrk = Emitron::Worker->new(
        sub {
          my ( $msg, $wtr ) = @_;
          sleep 2 + rand();
          my $data = $msg->msg;
          $data->{touched}++;
          print "[$$] Processed $data->{id} ($data->{touched})\n";
          Emitron::Message->new( message => $data )->send( $wtr );
        }
      );
      $active{ $wrk->pid } = $wrk;
      $rds->add( [ $wrk->reader, $wrk->pid ] );
    }
    my @rdy = $rds->can_read;

    for my $rd ( @rdy ) {
      my $wrk = $active{ $rd->[1] };
      die unless defined $wrk;
      my $msg = Emitron::Message->recv( $wrk->reader );
      die unless defined $msg;    # TODO

      if ( $msg->type eq 'signal' ) {
        $wrk->state( $msg->msg );
      }
      else {
        push @mq, $msg;
      }
    }

    my @active = sort { $a->pid <=> $b->pid } values %active;
    print
     join( ', ', map { sprintf "%s: %s", $_->pid, $_->state } @active ),
     "\n";

    my @ready = grep { $_->state eq 'READY' } values %active;
    while ( @ready && @mq ) {
      my $msg = pop @mq;
      my $wrk = pop @ready;
      $msg->send( $wrk->writer );
      $wrk->state( 'BUSY' );
    }

    #    WAIT: {
    #      print "$$ Waiting...\n";
    #      my $pid = waitpid -1, WNOHANG;
    #      if ( defined $pid && exists $active{$pid} ) {
    #        print "Reaping $pid\n";
    #        my $ar = delete $active{$pid};
    #        $rds->remove( $ar->[0] );
    #        $wrs->remove( $ar->[1] );
    #        $exs->remove( @$ar );
    #        close for @$ar;
    #        goto WAIT;
    #      }
    #    }
  }
}

# vim:ts=2:sw=2:sts=2:et:ft=perl

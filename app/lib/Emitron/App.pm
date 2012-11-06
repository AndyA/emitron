package Emitron::App;

use strict;
use warnings;

use Data::Dumper;
use Emitron::Message;
use Emitron::Model::Watched;
use Emitron::Runner;
use Emitron::Worker;

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
  Emitron::Runner->new( workers => $self->make_workers )->run;
}

sub make_workers {
  my $self = shift;
  my @w    = ();
  push @w, $self->make_event_watcher;
  push @w, $self->make_worker for 1 .. 3;
  return \@w;
}

sub make_event_watcher {
  my $self = shift;
  my $queue = Emitron::Model::Watched->new( root => QUEUE )->init;
  # AWOOGA: This means we drop any existing messages...
  my $rev = $queue->revision;
  my $ser = 0;
  return sub {
    my ( undef, $wtr ) = @_;
    while () {
      $ser = $queue->wait( $ser, 10 );
      my $nrev = $queue->revision;
      for my $r ( $rev + 1 .. $nrev ) {
        my $msg = $queue->checkout( $r );
        Emitron::Message->new( message => $msg )->send( $wtr )
         if defined $msg;
      }
      $rev = $nrev;
    }
  };
}

sub make_worker {
  my $self = shift;
  return sub {
    my ( $get, $wtr ) = @_;
    while ( my $msg = $get->() ) {
      my $data = $msg->msg;
      print Dumper( $data );
      #      Emitron::Message->new( message => $data )->send( $wtr );
    }
  };
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

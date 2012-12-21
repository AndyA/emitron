#!perl

use strict;
use warnings;

use Data::Dumper;
use Test::More;

use ForkPipe::Muxer;
use ForkPipe;

{
  my $workers = 3;
  ok my $mux = ForkPipe::Muxer->new;
  isa_ok $mux, 'ForkPipe::Muxer';

  my @fp = map { ForkPipe->new( $mux->context ) } ( 1 .. $workers );
  $mux->add(@fp);
  is scalar $mux->workers, $workers, "$workers workers";

  my $id  = 0;
  my @pid = ();
  for my $fp (@fp) {
    my $pid = $fp->fork;
    unless ($pid) {
      $fp->on(
        sub {
          my $msg = shift;
          $msg->{pid} = $$;
          $fp->send($msg);
          exit if $msg->{done};
        }
      );
      $fp->poll(0.1) while 1;
    }

    push @pid, $pid;

    for ( 1 .. 5 ) {
      $fp->send( { from => 'fp', id => ++$id } );
    }
  }

  for ( 1 .. 5 ) {
    $mux->send( { from => 'mux', id => ++$id } );
  }

  my @to_mux = ();
  my $done   = 0;
  $mux->on(
    sub {
      my $msg = shift;
      return unless defined $msg;    # TODO
      push @to_mux, $msg;
      $done++ if $msg->{done};
    }
  );

  #  $mux->broadcast( { done => 1 } );
  $mux->poll(1);
  print Dumper( \@to_mux );
}

done_testing();

# vim:ts=2:sw=2:et:ft=perl


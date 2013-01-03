#!perl

use strict;
use warnings;

use Test::More;

use ForkPipe::Muxer;
use ForkPipe;

use Data::Dumper;
use Time::HiRes qw( sleep );

{
  ok my $mux = ForkPipe::Muxer->new;
  isa_ok $mux, 'ForkPipe::Muxer';

  {
    my $hearty = ForkPipe->new( $mux->context );
    my $deaf   = ForkPipe->new( $mux->context );

    $mux->add( $hearty, $deaf );

    $hearty->spawn(
      sub {
        $hearty->on(
          msg => sub {
            my $msg = shift;
            $hearty->send($msg);
            exit if $msg->{done};
            sleep 0.1;
          }
        );
        $hearty->poll(0.5) while 1;
      }
    );

    $deaf->spawn(
      sub {
        while () {
          $deaf->send( { iam => 'not listening' } );
          $deaf->poll(0.1);
        }
      }
    );
  }

  is scalar $mux->workers, 2, "2 workers";

  my @echo = ();
  my @deaf = ();
  $mux->on(
    msg => sub {
      my $msg = shift;
      push @echo, $msg if exists $msg->{id};
      push @deaf, $msg if exists $msg->{iam};
    }
  );

  $mux->send( { id => $_ } ) for 1 .. 5;
  $mux->poll(1);
  $mux->broadcast( { done => 1 } );
  $mux->poll(1);

  is_deeply [@echo], [map { { id => $_ } } 1 .. 5], 'echo';
  ok scalar(@deaf) > 5, 'deaf';
}
done_testing();

# vim:ts=2:sw=2:et:ft=perl


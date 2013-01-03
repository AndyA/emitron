#!perl

use strict;
use warnings;

use Test::More;

use ForkPipe::Muxer;
use ForkPipe;

use Data::Dumper;
use Time::HiRes qw( sleep );

sub wire_handler($$) {
  my ( $name, $fp ) = @_;
  $fp->on(
    msg => sub {
      my $msg = shift;
      $msg->{from} = $name;
      $fp->send($msg);
      exit if $msg->{done};
      sleep 0.1;
    }
  );
}

{
  ok my $mux = ForkPipe::Muxer->new;
  isa_ok $mux, 'ForkPipe::Muxer';

  {
    my $hearty = ForkPipe->new( $mux->context );
    my $doomed = ForkPipe->new( $mux->context );

    $mux->add( $hearty, $doomed );

    $hearty->spawn(
      sub {
        wire_handler hearty => $hearty;
        $hearty->poll(0.5) while 1;
      }
    );

    $doomed->spawn(
      sub {
        wire_handler doomed => $doomed;
        $doomed->poll(0.5);
      }
    );
  }

  is scalar $mux->workers, 2, "2 workers";

  my @reaped = ();
  $mux->on( child => sub { push @reaped, @_ } );

  my @to_mux = ();
  $mux->on( msg => sub { push @to_mux, @_ } );

  $mux->send( { id => $_ } ) for 1 .. 5;
  $mux->poll(2);
  is_deeply [@reaped], [{ status => 0 }], 'doomed child exited';
  $mux->broadcast( { done => 1 } );
  $mux->poll(2);
  is_deeply [@reaped], [{ status => 0 }, { status => 0 }],
   'other child exited';
}
done_testing();

# vim:ts=2:sw=2:et:ft=perl


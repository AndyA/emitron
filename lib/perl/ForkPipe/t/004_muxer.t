#!perl

use strict;
use warnings;

use Test::More;

use ForkPipe::Muxer;
use ForkPipe;

use Time::HiRes qw( sleep );

sub child($$) {
  my ( $fp, $id ) = @_;
  $fp->on(
    msg => sub {
      my $msg = shift;
      $msg->{kid} = $id;
      $fp->send($msg);
      exit if $msg->{done};
      sleep 0.1;
    }
  );
  $fp->poll(0.1) while 1;
}

{
  my $workers  = 3;
  my $messages = 5;
  ok my $mux = ForkPipe::Muxer->new;
  isa_ok $mux, 'ForkPipe::Muxer';

  my @fp = map { ForkPipe->new( $mux->context ) } ( 1 .. $workers );
  $mux->add(@fp);
  is scalar $mux->workers, $workers, "$workers workers";

  my $id  = 0;
  my $kid = 0;
  my @pid = ();
  for my $fp (@fp) {
    $kid++;
    my $pid = $fp->fork;
    child $fp, $kid unless $pid;
    push @pid, $pid;

    for ( 1 .. $messages ) {
      $fp->send( { from => 'fp', id => ++$id } );
    }
  }

  for ( 1 .. $messages ) {
    $mux->send( { from => 'mux', id => ++$id } );
  }

  my @to_mux = ();
  my $done   = 0;
  $mux->on(
    msg => sub {
      my $msg = shift;
      return unless defined $msg;    # TODO
      if ( $msg->{done} ) {
        $done++;
      }
      else {
        push @to_mux, $msg;
      }
    }
  );

  $mux->poll(0.5);
  $mux->broadcast( { done => 1 } );
  $mux->poll(1);

  is $id, $workers * $messages + $messages, 'messages sent as expected';
  is $done, $workers, 'all workers accounted for';

  my %want = map { $_ => 1 } ( 1 .. $id );
  my %used = ();
  my %from = ();

  for my $msg (@to_mux) {
    my $id = $msg->{id};
    ok exists $want{$id}, "message $id was expected";
    delete $want{$id};
    $used{ $msg->{kid} }++;
    $from{ $msg->{from} }++;
  }

  is 0, keys %want, 'all ids accounted for';
  is_deeply \%from, { mux => $messages, fp => $messages * $workers },
   'mux, fp messages seen';

  is_deeply [sort { $a <=> $b } keys %used],
   [1 .. $workers], "all $workers workers used";
}

done_testing();

# vim:ts=2:sw=2:et:ft=perl


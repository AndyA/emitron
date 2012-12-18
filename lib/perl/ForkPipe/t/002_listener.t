#!perl

use strict;
use warnings;

use IO::Handle;
use Test::Differences;
use Test::More;
use Time::HiRes qw( time );

use ForkPipe::Listener;

sub elapsed(&) {
  my $cb  = shift;
  my $now = time;
  $cb->();
  return time - $now;
}

sub mk_pipe() {
  my $rdr = IO::Handle->new;
  my $wtr = IO::Handle->new;
  pipe $rdr, $wtr or die "Can't make pipe: $!";
  return ( $rdr, $wtr );
}

sub drain($) {
  my $fh = shift;
  while () {
    my $got = $fh->sysread( my $buf, 1024 );
    die "I/O error: $!" unless defined $got;
    last if $got < 1024;
  }
}

sub test_it(&) {
  my $poller = shift;

  ok my $li = ForkPipe::Listener->new, "new";
  isa_ok $li, 'ForkPipe::Listener';

  my ( $r1, $w1 ) = mk_pipe;
  my ( $r2, $w2 ) = mk_pipe;
  my $cl = {};

  my $cb = sub {
    my ( $fh, $nm ) = @_;
    $cl->{$nm}++;
    drain $fh;
  };

  $li->add( $r1, $cb, 'r1' );
  $li->add( $r2, $cb, 'r2' );

  $poller->( $li );

  eq_or_diff $cl, {}, "no callbacks";

  $w1->syswrite( "Boo!" );
  $w1->flush;

  $poller->( $li );

  eq_or_diff $cl, { r1 => 1 }, "r1 callback";

  $poller->( $li );

  eq_or_diff $cl, { r1 => 1 }, "no callbacks";

  $w1->syswrite( "Boo!" );
  $w1->flush;
  $w2->syswrite( "Boo!" );
  $w2->flush;

  $poller->( $li );

  eq_or_diff $cl, { r1 => 2, r2 => 1 }, "r1, r2 callback";

  $li->remove( $r1 );

  $w1->syswrite( "Boo!" );
  $w1->flush;
  $w2->syswrite( "Boo!" );
  $w2->flush;

  $poller->( $li );

  eq_or_diff $cl, { r1 => 2, r2 => 2 }, "r2 callback";

  eq_or_diff $li->stats, { handled => 4 }, 'stats';
}

test_it {
  my $li = shift;
  my $tm = elapsed { $li->poll( 0.5 ) };
  ok $tm >= 0.4 && $tm <= 2, "timeout";
};

test_it { shift->peek };

done_testing();

# vim:ts=2:sw=2:et:ft=perl


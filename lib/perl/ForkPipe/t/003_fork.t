#!perl

use strict;
use warnings;

use Test::Differences;
use Test::More;

use Data::Dumper;

use ForkPipe;

{
  ok my $fp = ForkPipe->new, 'new';
  isa_ok $fp, 'ForkPipe';

  my $running = 1;
  my @got     = ();
  if ( my $pid = $fp->fork ) {
    $fp->on(
      sub {
        my $msg = shift;
        #        $fp->log( Dumper( $msg ) );
        if ( $msg->{done} ) {
          $running = 0;
          return;
        }

        push @got, $msg->{sn};
        $msg->{sn} *= 2;
        $fp->send( $msg );
      }
    );
    $fp->send( { sn => 1 } );
    $fp->poll( 0.1 ) while $running;
    waitpid $pid, 0;
  }
  else {
    $fp->on(
      sub {
        my $msg = shift;
        #        $fp->log( Dumper( $msg ) );
        if ( $msg->{sn}++ > 500 ) {
          $msg->{done} = 1;
          $running = 0;
        }
        $fp->send( $msg );
      }
    );
    $fp->poll( 0.1 ) while $running;
    exit;
  }
  eq_or_diff \@got, [ 2, 5, 11, 23, 47, 95, 191, 383 ], 'messages';
}

done_testing();

# vim:ts=2:sw=2:et:ft=perl


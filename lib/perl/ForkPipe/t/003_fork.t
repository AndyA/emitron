#!perl

use strict;
use warnings;

use Test::Differences;
use Test::More;

use Data::Dumper;
use POSIX ":sys_wait_h";

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

{
  my $fp = ForkPipe->new;

  my $parent = sub {
    my $msg = shift;
    my $gsm = reverse $msg;
    return $gsm;
  };

  my $child = sub {
    my $msg = shift;
    return if length( $msg ) > 1_000_000;
    ( my $ext = $msg ) =~ tr/A-Za-z/ZzA-Ya-y/;
    my $out = join ' ', $msg, $ext;
    return $out;
  };

  my $init = 'Another Porky Prime Cut';

  my $want = run_them( $parent, $child, $init );
  my $got = fork_them( $parent, $child, $init, $fp );

  # don't want to print huge value on failure
  ok $got eq $want, 'long message';

  # Fragile 
  eq_or_diff $fp->stats,
   {
    'msg' => {
      'receive' => 17,
      'send'    => 17,
      'read'    => 3146076,
      'write'   => 3146168
    },
    'ctl' => {
      'receive' => 18,
      'read'    => 486
    }
   },
   'stats';
}

done_testing();

sub run_them {
  my ( $parent, $child, $msg ) = @_;
  for ( ;; ) {
    my $nm = $child->( $msg );
    return $msg unless defined $nm;
    $msg = $parent->( $nm );
  }
}

sub fork_them {
  my ( $parent, $child, $msg, $fp ) = @_;

  my $pid = $fp->fork;
  unless ( $pid ) {
    $fp->on(
      sub {
        my $msg = shift;
        my $nm  = $child->( $msg );
        $fp->send( $nm );
        exit 0 unless defined $nm;
      }
    );

    $fp->poll( 0.1 ) while 1;
  }

  my ( $out, $done );

  $fp->on(
    sub {
      my $msg = shift;
      if ( defined $msg ) {
        $fp->send( $out = $parent->( $msg ) );
        return;
      }
      $done++;
    }
  );

  $fp->send( $msg );
  $fp->poll( 0.1 ) until $done;

  return $out;
}

# vim:ts=2:sw=2:et:ft=perl


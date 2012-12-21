#!perl

use strict;
use warnings;

use Test::More tests => 100;
use Harmless::M3U8;

sub test_cleanup {
  my $pl   = Harmless::M3U8->new;
  my $want = 0;
  my $sf   = seg_factory();
  for ( 1 .. 100 ) {
    is $pl->segment_count, $want, "segment_count";
    $pl->push_segment( $sf->() );
    $want++;
    $pl->push_discontinuity if rand() < 0.2;
    $pl->cleanup(11);
    $want = 11 if $want > 11;
  }
}

test_cleanup();

sub seg_factory {
  my $next = shift || 0;
  return sub {
    return {
      uri      => sprintf( 'test/%08d.ts', $next++ ),
      duration => 3.9770,
      title    => '',
    };
  };
}

sub dd {
  use Data::Dumper;
  Data::Dumper->new(@_)->Indent(2)->Quotekeys(0)->Useqq(1)->Dump;
}

# vim:ts=2:sw=2:et:ft=perl


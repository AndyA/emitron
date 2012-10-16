#!/usr/bin/env perl

require 5.010;

use strict;
use warnings;

use Data::Dumper;
use POSIX qw( strftime );
use Term::ANSIColor;
use Time::HiRes qw( usleep  );

use lib qw( app/lib );
use NewStream::EvoStream;

use constant {
  FATAL   => 1,
  ERROR   => 2,
  WARNING => 3,
  INFO    => 4,
  DEBUG   => 5,
};

my @LOGCOLOUR
 = ( undef, 'red on_white', 'red on_white', 'yellow', 'cyan',
  'green', );

our $LOGLEVEL = DEBUG;

my $Streams = {};    # by id

sub ts {
  my $now = shift // Time::HiRes::time;
  return join '.', ( strftime '%Y/%m/%d %H:%M:%S', gmtime( $now ) ),
   sprintf( '%06d', $now * 1_000_000 % 1_000_000 );
}

sub mention {
  my $level = shift;
  return if $level > $LOGLEVEL;
  my $msg = join '', @_;
  my $ts = ts;
  print color $LOGCOLOUR[$level] // 'white';
  print "$ts: $_\n" for split /\n/, $msg;
  print color 'reset';
}

sub list_streams {
  my $evo   = shift;
  my $sl    = $evo->list_streams;
  my $by_id = {};
  for my $stm ( @{ $sl->{data} } ) {
    $by_id->{ $stm->{uniqueId} } = $stm;
  }
  return $by_id;
}

sub run {
  mention INFO, "NewStream starting";
  my $evo = NewStream::EvoStream->new( host => 'localhost' );
  while () {
    mention DEBUG, "Polling";
    print Dumper( list_streams( $evo ) );
    sleep 1;
  }
}

run;

# vim:ts=2:sw=2:sts=2:et:ft=perl


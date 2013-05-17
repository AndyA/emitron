#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;
use Hash::Merge::Simple qw( merge );
use Net::Icecast::Source;
use POSIX qw( mkfifo );
use Path::Class;

use constant ENVIRONMENT => 'dev';

my %DEFAULT = (
  global => {
    connect => {
      username  => 'source',
      mime_type => 'audio/aac',
    },
    meta => {
      name        => 'Radio 5live Test',
      description => '',
      url         => 'http://icecast.org',
    },
    encode => {
      script => 'encoder/jack_aac.sh',
      work   => "tmp/r5live.$$",
      rate   => 48000,
    },
  },
  test => {
    connect => {
      password => '123.$$ices',
      server   => 'ic.prototype0.net',
      port     => '8000',
    },
  },
  dev => {
    connect => {
      password => 'froonbat1127',
      server   => 'igloo.fenkle',
      port     => '8000',
    },
  },
);

my @CHANNELS = (
  { connect => { mount_point => '/commentary', },
    encode  => {
      name     => 'commentary.aac',
      bit_rate => '128k',
      input    => ['system:capture_1'],
    },
    enabled => 1,
  },
  { connect => { mount_point => '/arena1', },
    encode  => {
      name     => 'arena1.aac',
      bit_rate => '128k',
      input    => ['system:capture_5', 'system:capture_6'],
    },
    enabled => 1,
  },
  { connect => { mount_point => '/arena2', },
    encode  => {
      name     => 'arena2.aac',
      bit_rate => '128k',
      input    => ['system:capture_7', 'system:capture_8'],
    },
    enabled => 1,
  },
);

for my $channel (@CHANNELS) {
  next unless $channel->{enabled};

  my $spec = merge $DEFAULT{global}, $DEFAULT{&ENVIRONMENT}, $channel;

  launch($spec);
}

wait;

sub launch {
  my $spec = shift;

  # Connect before forking
  my $src = Net::Icecast::Source->new( %{ $spec->{connect} } );

  $src->connect or die "Can't connect: $!\n";
  $src->login   or die "Can't login\n";

  my $fifo = run_encoder($spec);

  my $pid = fork;
  defined $pid or die "Can't fork: $!\n";
  unless ($pid) {
    open my $fh, '<', $fifo or die "Can't open $fifo: $!\n";
    $fh->binmode;
    $src->stream_fh($fh);
    $fh->close;
    $src->disconnect;
    exit;
  }
}

sub run_encoder {
  my $spec   = shift;
  my %encode = %{ $spec->{encode} };
  my @args   = @{ delete $encode{input} };
  my %env    = ();
  my $fifo   = $encode{fifo} = file( $encode{work}, $encode{name} );
  my $log    = $encode{log} = file( $encode{work}, "$encode{name}.log" );
  $fifo->parent->mkpath;
  $fifo->remove;
  mkfifo "$fifo", 0600 or die "Can't create fifo $fifo: $!\n";

  while ( my ( $k, $v ) = each %encode ) {
    $env{ 'ENC_' . uc $k } = "$v";
  }

  my $pid = fork;
  defined $pid or die "Can't fork: $!\n";
  unless ($pid) {
    my @k = keys %env;
    local @ENV{@k} = @env{@k};
    exec 'bash', $encode{script}, @args;
    die;
  }

  return $fifo;
}

# vim:ts=2:sw=2:sts=2:et:ft=perl

## Please see file perltidy.ERR

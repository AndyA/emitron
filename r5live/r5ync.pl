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

broadcast(@CHANNELS);
wait;

sub escape {
  map { /\s/ ? qq{'$_'} : $_ } @_;
}

sub fexec {
  my $cmd = join ' ', escape @_;
  my $pid = fork;
  defined $pid or die "Fork failed: $!\n";
  unless ($pid) {
    print "## [$$] $cmd\n";
    exec 'bash', -c => $cmd;
    die;
  }
}

sub broadcast {
  my @ch = @_;

  my @cmd  = ( 'ffmpeg', '-y' );
  my @tee  = ();
  my @info = ();
  my $seq  = 0;
  my @conn = ();

  for my $channel (@ch) {
    next unless $channel->{enabled};

    my $spec = merge $DEFAULT{global}, $DEFAULT{&ENVIRONMENT}, $channel;
    ( my $name = $spec->{encode}{name} ) =~ tr/./_/;

    push @cmd, make_ffmpeg_args( $name, $spec, $seq );
    my ( $outfifo, $log )
     = map { file( $spec->{encode}{work}, "$name.$_" ) } 'aac', 'log';

    make_fifo($outfifo);

    push @info, [$outfifo, $log, get_connection($spec)];
    push @tee, '|', 'tee', '>(', 'ffmpeg', '-y',
     -f   => 'latm',
     -i   => '-',
     -c   => 'copy',
     -map => "0:$seq",
     "$outfifo", '<', '/dev/null', '2>', "$log", ')';

    my $ix = 1;
    for my $inp ( @{ $spec->{encode}{input} } ) {
      push @conn, ['jack_connect', $inp, "$name:input_$ix"];
      $ix++;
    }
    $seq++;
  }

  push @cmd,
   '-c:a'   => 'libfaac',
   '-bsf:a' => 'aac_adtstoasc',
   -f       => 'latm',
   '-', '<', '/dev/null', '>', '/dev/null';

  fexec @cmd, @tee;

  sleep 2;

  for my $conn (@conn) {
    print "### ", join( ' ', @$conn ), "\n";
    system @$conn and die "Failed: $?\n";
    sleep 1;
  }

  $seq = 0;
  for my $info (@info) {
    my ( $outfifo, $log, $src ) = @$info;
    pump( $src, $outfifo );
  }
}

sub pump {
  my ( $src, $fifo ) = @_;

  print "# pumping from $fifo\n";

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

sub make_fifo {
  my $fifo = shift;
  $fifo->parent->mkpath;
  $fifo->remove;
  mkfifo "$fifo", 0600 or die "Can't create $fifo: $!\n";
}

sub make_ffmpeg_args {
  my ( $name, $spec, $seq ) = @_;
  return (
    -ac  => scalar( @{ $spec->{encode}{input} } ),
    -f   => 'jack',
    -i   => $name,
    -map => "$seq:0",
  );
}

sub get_connection {
  my $spec = shift;

  my $src = Net::Icecast::Source->new( %{ $spec->{connect} } );

  $src->connect or die "Can't connect: $!\n";
  $src->login   or die "Can't login\n";

  return $src;
}

# vim:ts=2:sw=2:sts=2:et:ft=perl


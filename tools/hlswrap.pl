#!/usr/bin/env perl

use strict;
use warnings;

use File::Basename qw( basename );
use File::Spec;
use Data::Dumper;
use Getopt::Long;
use Time::HiRes qw( sleep );

use constant GOP  => 8;
use constant FRAG => '%05d.ts';

my %KLUDGE = (
  1 => 396,
  2 => 800,
  3 => 1500,
  4 => 2096,
);

GetOptions() or die;

my $dir = shift
 || die "Please name the directory containing the fragment directories";

my @stm = stm->find_streams( $dir );
die "No streams found" unless @stm;
write_master( $dir, @stm );

$SIG{INT} = sub {
  print "Closing stream\n";
  for my $stm ( @stm ) {
    $stm->close;
    $stm->write_list;
  }
};

while () {
  my $got = 0;
  $got += $_->find_frags for @stm;
  sleep GOP;
  if ( $got ) {
    $_->write_list for @stm;
  }
}

sub write_master {
  my ( $dir, @stm ) = @_;
  my $name = basename $dir;
  my $list = File::Spec->catfile( $dir, "$name.m3u8" );
  my $tmp  = "$list.tmp";
  {
    open my $fh, '>', $tmp or die "Can't write $tmp: $!\n";
    print $fh "#EXTM3U\n";
    my %pl = ();
    for my $stm ( @stm ) {
      my $sd = $stm->dir;
      die unless $sd =~ /(\d+)$/;
      my $idx = $1;
      my $bw  = $KLUDGE{$idx} * 1000;
      $pl{$idx} = join "\n",
       "#EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=$bw", $stm->list;
    }
    for my $idx ( sort { $a <=> $b } keys %pl ) {
      print $fh $pl{$idx}, "\n";
    }
  }
  rename $tmp, $list or die "Can't rename $tmp as $list: $!\n";
}

sub stm::find_streams {
  my ( $class, $dir ) = @_;
  my $name = basename $dir;
  my $like = qr{^\Q$name\E-\d+$};
  opendir my $dh, $dir or die "Can't read $dir: $!\n";
  return
   map { $class->new( base => $dir, dir => $_, list => "$_.m3u8", ); }
   grep { $_ =~ $like } readdir $dh;
}

sub stm::new {
  my ( $class, %args ) = @_;
  return bless {
    %args,
    frags  => [],
    next   => 1,
    closed => 0,
  }, $class;
}

sub stm::base { shift->{base} }
sub stm::dir  { shift->{dir} }
sub stm::list { shift->{list} }
sub stm::next { shift->{next} }

sub stm::find_frags {
  my $self = shift;
  my $got  = 0;
  while () {
    my $frag = sprintf FRAG, $self->next;
    my $try = File::Spec->catfile( $self->base, $self->dir, $frag );
    last unless -f $try;
    $got++;
    $self->{next}++;
    push @{ $self->{frags} }, join '/', $self->dir, $frag;
    print "Found $frag\n";
  }
  return $got;
}

sub stm::write_list {
  my $self = shift;
  my $list = File::Spec->catfile( $self->base, $self->list );
  my $tmp  = "$list.tmp";
  {
    open my $fh, '>', $tmp or die "Can't write $tmp: $!\n";
    print $fh join "\n",
     '#EXTM3U',
     '#EXT-X-VERSION:3',
     '#EXT-X-TARGETDURATION:' . GOP,
     '#EXT-X-ALLOW-CACHE:YES',
     '#EXT-X-MEDIA-SEQUENCE:1', '';
    for my $frag ( @{ $self->{frags} } ) {
      print $fh join "\n", "#EXTINF:" . GOP, $frag, '';
    }
    print $fh "#EXT-X-ENDLIST\n" if $self->{closed};
  }
  rename $tmp, $list or die "Can't rename $tmp as $list: $!\n";
  print "Updated $list\n";
}

sub stm::close { shift->{closed} = 1 }

# vim:ts=2:sw=2:sts=2:et:ft=perl


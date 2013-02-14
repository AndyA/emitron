#!/usr/bin/env perl

use strict;
use warnings;

use File::Basename qw( basename );
use File::Find;
use JSON;
use Path::Class;

sub first {
  -e && return $_ for @_;
  return;
}

use constant DB   => 'stash/db.json';
use constant BASE => first( '/Volumes/Meeja', glob '~/ACE' );
use constant ROOT => BASE
 . '/ACE/132.185.236.109/thespace/'
 . 'original_submissions_6tb_disc4/ACE Film Collection';

use constant OUT => BASE . '/ACE/raw';

my $db = JSON->new->utf8->decode( scalar file(DB)->slurp );

my %fixup = (
  ACE029 => ['Copy_Arts_Council_SSB_16476/2ND DELIVERY/ACE029.MPG'],
  ACE462 => [
    'Copy_Arts_Council_SSB_16476/2ND DELIVERY/ACE462_ONEmpeg21.mpg',
    'Copy_Arts_Council_SSB_16476/2ND DELIVERY/ACE462_TWOmpeg21.mpg',
    'Copy_Arts_Council_SSB_16476/2ND DELIVERY/ACE462_THREEmpeg21.mpg',
  ],
);

my $cat = catalogue(ROOT);

#print JSON->new->canonical->pretty->encode($cat);

my $out = dir OUT;
$out->mkpath;

for my $rec (@$db) {
  my $id = $rec->{'Film ID'};
  die "Missing ID" unless defined $id;
  my @files = find_master($id);
  my $out = file $out, "$id.mpg";
  if ( -e $out ) {
    print "$out exists\n";
    next;
  }
  print "$out\n";
  if ( @files > 1 ) {
    concat( "$out", @files );
  }
  else {
    link $files[0], "$out";
  }
}

sub concat {
  my ( $dst, @src ) = @_;
  my $tmp = "/tmp/$$.list";
  {
    my $fh = file($tmp)->openw;
    print $fh "file '$_'\n" for @src;
  }
  system ffmpeg => -f => 'concat', -i => $tmp, -c => 'copy', $dst;
  unlink $tmp;
}

sub find_master {
  my $id = shift;

  return map { file ROOT, $_ } @{ $fixup{$id} } if $fixup{$id};

  my $files = $cat->{$id};

  unless ($files) {
    print "No assets for $id\n";
    next;
  }

  my @got = ();
  for my $me ( sort @{$files} ) {
    my $nm = basename $me;
    if ( $nm =~ /^$id(?:1mpeg2|mpeg21).*\.mpg$/ ) {
      push @got, $me;
    }
  }

  unless (@got) {
    print "No MPEG movie for $id\n";
    print "  $_\n" for @{$files};
    die;
  }

  @got = sort { -s $b <=> -s $a } @got;

  if ( @got > 1 ) {
    print "Multiple MPEG candidates for $id\n";
  }

  return $got[0];
}

sub catalogue {
  my @dir = @_;
  my $cat = {};
  find {
    wanted => sub {
      return unless -f;
      my $bucket = /^(ACE\d\d\d)/i ? uc $1 : 'unknown';
      push @{ $cat->{$bucket} }, $File::Find::name;
     }
  }, @dir;
  return $cat;
}

# vim:ts=2:sw=2:sts=2:et:ft=perl


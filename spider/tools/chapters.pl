#!/usr/bin/env perl

use strict;
use warnings;

use JSON;
use Path::Class;

use constant DB => 'stash/db.json';

my $db = JSON->new->utf8->decode( scalar file(DB)->slurp );

for my $rec (@$db) {

  my $id = $rec->{'Film ID'};
  die "Missing ID" unless defined $id;

  my $syn = $rec->{'Full synopsis'};
  unless ( defined $syn ) {
    print "$id has no synopsis\n";
    next;
  }

  $syn =~ s/\x0b/ /g;

  my $min = $rec->{'Minutes'};
  my $dur = defined $min && $min =~ /^(\d+)\s+min$/ ? $1 * 60 : undef;

  print "$id";
  print " (", encode_time($dur), ")" if defined $dur;
  print "\n";

  my %frag = ();
  {
    my $hdr  = qr{$id\.(\d+)};
    my $lpos = 0;
    my $cidx = undef;
    while ( $syn =~ /\b($hdr)\b/g ) {
      my ( $cid, $idx ) = ( $1, $2 );
      my $npos = pos($syn);
      my $pfx  = $npos - length $cid;
      $frag{$cidx} = trim( substr $syn, $lpos, $pfx - $lpos )
       if $lpos < $pfx && defined $cidx;
      ( $lpos, $cidx ) = ( $npos, $idx );
    }
    $frag{$cidx} = trim( substr $syn, $lpos ) if defined $cidx;
  }

  my @chap = ();
  {
    my $hour = undef;
    for my $cp ( sort { $a <=> $b } keys %frag ) {
      my @p = split /\s+/, $frag{$cp}, 3;
      printf "%3d : %s\n", $cp, join ' : ', @p[0 .. 1];
      my $in = decode_time( shift @p );
      die "Bad in time in $cp\n" unless defined $in;
      my $out = decode_time( shift @p );
      die "Bad out time in $cp\n" unless defined $out;
      $hour = int( $in / 3600 ) * 3600 unless defined $hour;
      unless ( defined $hour ) {
      }
      push @chap,
       {in   => $in - $hour,
        out  => $out - $hour,
        desc => @p,
       };
    }
  }
  $rec->{chapters} = \@chap;

}

{
  my $tmp = DB . '.tmp';
  my $bak = DB . '.bak';
  my $fh  = file($tmp)->openw;
  $fh->binmode(':utf8');
  print $fh JSON->new->pretty->canonical->encode($db);
  rename DB, $bak or die $!;
  rename $tmp, DB or die $!;
}

sub decode_time {
  my $tm = shift;
  return unless $tm =~ /^(\d\d):(\d\d):(\d\d)$/;
  my ( $h, $m, $s ) = ( $1, $2, $3 );
  return unless $h < 24 && $m < 60 && $s < 60;
  return ( $h * 60 + $m ) * 60 + $s;
}

sub encode_time {
  my $tm = shift;
  sprintf "%02d:%02d:%02d", int( $tm / 60 / 60 ) % 24,
   int( $tm / 60 ) % 60, int($tm) % 60;
}

sub trim {
  my $s = shift;
  for ($s) {
    s/^\s+//;
    s/\s+$//;
    s/\s+/ /g;
  }
  return $s;
}

# vim:ts=2:sw=2:sts=2:et:ft=perl


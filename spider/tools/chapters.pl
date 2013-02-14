#!/usr/bin/env perl

use strict;
use warnings;

use JSON;
use Path::Class;

use constant DB => 'stash/db.json';

my $db = JSON->new->decode( scalar file(DB)->slurp );

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

  my %chap = ();

  {
    my $hdr  = qr{$id\.(\d+)};
    my $lpos = 0;
    my $cidx = undef;
    while ( $syn =~ /\b($hdr)\b/g ) {
      my ( $cid, $idx ) = ( $1, $2 );
      my $npos = pos($syn);
      my $pfx  = $npos - length $cid;
      #    print "  $cid $lpos $pfx\n";
      $chap{$cidx} = trim( substr $syn, $lpos, $pfx - $lpos )
       if $lpos < $pfx && defined $cidx;
      ( $lpos, $cidx ) = ( $npos, $idx );
    }
    $chap{$cidx} = trim( substr $syn, $lpos ) if defined $cidx;
    #  print JSON->new->pretty->encode( \%chap );
  }

  {
    my $prev = undef;
    for my $cp ( sort { $a <=> $b } keys %chap ) {
      my @p = split /\s+/, $chap{$cp}, 3;
      printf "%3d : %s\n", $cp, join ' : ', @p[0 .. 1];
      my $in = decode_time( $p[0] );
      die "Bad in time: $p[0] in $cp\n" unless defined $in;
      my $out = decode_time( $p[1] );
      die "Bad out time: $p[1] in $cp\n" unless defined $out;
    }
  }

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


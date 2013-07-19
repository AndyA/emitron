#!/usr/bin/env perl

use strict;
use warnings;

use File::Find;
use JSON;
use Path::Class;
use XML::LibXML::XPathContext;
use XML::LibXML;

use constant ELVIS => 'app/public/asset/elvis';
use constant STASH => file( ELVIS, 'stash.json' );

my %db = ();
find {
  no_chdir => 1,
  wanted   => sub {
    return unless -f && /\.xml$/;
    my $obj = file($_);
    print "\r$obj", ('   ') x 3;
    my $rel = $obj->absolute->relative(ELVIS);
    my ( $kind, $base ) = split /\//, $rel;
    ( my $id = $base ) =~ s/\.xml$//;
    {
      my $fh = $obj->openr;
      $fh->binmode(':encoding(cp1252)');
      my $xml = do { local $/; <$fh> };
      my $dd = parse_elvis($xml);
      $db{$id}{$kind} = $dd;
    }
  },
 },
 ELVIS;

print "\n";
my $fh = STASH->openw;
$fh->binmode(':utf8');
print $fh JSON->new->canonical->pretty->encode( \%db );

sub parse_elvis {
  my $xml = shift;
  my $dom = XML::LibXML->load_xml( string => $xml );
  my $xp  = XML::LibXML::XPathContext->new($dom);

  my @d = ();
  for my $img ( $xp->findnodes('/elvisimage') ) {
    my $rec = {};
    for my $nd ( $img->nonBlankChildNodes ) {
      $rec->{ $nd->nodeName } = $nd->textContent;
    }
    push @d, $rec;
  }
  return $d[0];
}

# vim:ts=2:sw=2:sts=2:et:ft=perl


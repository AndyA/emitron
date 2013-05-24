#!/usr/bin/env perl

use strict;
use warnings;

use JSON;
use Path::Class;
use XML::LibXML::XPathContext;
use XML::LibXML;

my $xml = do { local $/; <> };

my $dom = XML::LibXML->load_xml( string => $xml );
my $xp = XML::LibXML::XPathContext->new($dom);

my $meta = { media => { duration => find_best( $xp, 'Duration' ) / 1000, 
   },
 };
print JSON->new->pretty->canonical->encode($meta);

sub find_best {
  my ( $xp, $fld ) = @_;
  my ($vv);
  for my $nd ( $xp->findnodes("/Mediainfo/File/track/$fld") ) {
    my $v = $nd->textContent;
    next unless $v =~ /^\s*(\d+)\s*$/;
    $vv = $v unless defined $vv && $vv > $v;
  }
  return $vv;
}

# vim:ts=2:sw=2:sts=2:et:ft=perl


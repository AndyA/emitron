#!/usr/bin/env perl

use strict;
use warnings;

use File::Find;
use JSON;
use Path::Class;
use XML::LibXML::XPathContext;
use XML::LibXML;

use constant ELVIS => 'app/public/asset/elvis';
use constant SHAPE => file( ELVIS, 'shape.json' );

use constant CARDINALITY_MAX => 200;

$| = 1;

my %CLASS = (
  INT      => qr{^-?\d+$},
  POS_INT  => qr{^\d+$},
  NUMBER   => qr{^-?\d+(?:\.\d+)?$},
  EMPTY    => qr{^\s*$},
  ONE_WORD => qr{^\w+$},
  NULL     => undef,
);

my $shape = {};
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
      my $dd = parse_elvis( $shape, $xml );
    }
  },
 },
 ELVIS;

print "\n";
post_process($shape);
my $fh = SHAPE->openw;
$fh->binmode(':utf8');
print $fh JSON->new->canonical->pretty->encode($shape);

sub post_process {
  my $shape = shift;
  for my $sh ( values %$shape ) {
    my $card = $sh->{cardinality};
    $sh->{cardinality}
     = $card->{too_long}
     ? undef
     : keys %{ $card->{values} };
  }
}

sub parse_elvis {
  my ( $shape, $xml ) = @_;
  my $dom = XML::LibXML->load_xml( string => $xml );
  my $xp = XML::LibXML::XPathContext->new($dom);

  for my $img ( $xp->findnodes('/elvisimage') ) {
    for my $nd ( $img->nonBlankChildNodes ) {
      field_shape( $shape->{ $nd->nodeName } ||= {}, $nd->textContent );
    }
  }
}

sub field_shape {
  my ( $shape, $value ) = @_;

  $shape->{count}++;

  if ( defined $value ) {
    my $len = length $value;
    my $linfo = $shape->{length} ||= {};

    $linfo->{min} = $len
     unless defined $linfo->{min} && $linfo->{min} < $len;
    $linfo->{max} = $len
     unless defined $linfo->{max} && $linfo->{max} > $len;

    if ( $len < CARDINALITY_MAX ) {
      $shape->{cardinality}{values}{$value}++;
    }
    else {
      $shape->{cardinality}{too_long}++;
    }
  }

  while ( my ( $class, $like ) = each %CLASS ) {
    $shape->{class}{$class}++
     if ( defined $value && defined $like && $value =~ $like )
     || ( !defined $value && !defined &like );
  }
}

# vim:ts=2:sw=2:sts=2:et:ft=perl


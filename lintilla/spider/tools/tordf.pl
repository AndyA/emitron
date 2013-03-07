#!/usr/bin/env perl

use strict;
use warnings;

use JSON;
use Path::Class;
use RDF::Helper;
use RDF::Trine;
use RDF::Helper::Constants qw(:dc);
use RDF::Trine::Serializer::RDFXML;

use constant DB => 'stash/db.json';

my ( %fountain, %stash );

my $db = JSON->new->utf8->decode( scalar file(DB)->slurp );

my %ns = (
  dcmit => 'http://purl.org/dc/dcmitype/',
  dct   => 'http://purl.org/dc/terms/',
  event => 'http://purl.org/NET/c4dm/event.owl#',
  foaf  => 'http://xmlns.com/foaf/0.1/',
  ore   => 'http://www.openarchives.org/ore/terms/',
  owl   => 'http://www.w3.org/2002/07/owl#',
  rdf   => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
  rdfs  => 'http://www.w3.org/2000/01/rdf-schema#',
  sem   => 'http://semanticweb.cs.vu.nl/2009/11/sem/',
  skos  => 'http://www.w3.org/2008/05/skos#',
  void  => 'http://rdfs.org/ns/void#',
  xsd   => 'http://www.w3.org/2001/XMLSchema#',
);

my $rdf = RDF::Helper->new(
  BaseInterface => 'RDF::Trine',
  namespaces    => {%ns},
  ExpandQNames  => 1
);

for my $rec (@$db) {
  load_rec($rec);
}

my $mod = $rdf->model;

my $ser = RDF::Trine::Serializer::RDFXML->new( namespaces => \%ns );
print $ser->serialize_model_to_string($mod);

sub words { join ' ', grep defined $_ && $_ ne '', @_ }

sub resource_uri {
  my ( $key, $val ) = @_;
  return join '', '/', $key, '/',
   ( $stash{$key}{$val} ||= ++$fountain{$key} ), '#id';
}

sub load_rec {
  my $rec = shift;

  my $id = delete $rec->{'Film ID'};
  die "Undefined ID" unless defined $id;
  my $ruri = resource_uri( 'media' => $id );

  #  print "$ruri\n";

  $rec->{title} = words( delete @{$rec}{ 'Article', 'Title' } );

  my %mapper = (
    'Choreographer'      => undef,
    'Date'               => 'dct:date',
    'Director'           => undef,
    'Full credits'       => undef,
    'Full synopsis'      => undef,
    'Minutes'            => undef,
    'Part'               => undef,
    'Production Company' => sub {
      my $val = shift;
      my $uri = resource_uri( 'company' => $val );
      $rdf->assert_literal( $uri, 'foaf:Agent', $val );
      #      my $co  = $rdf->new_bnode;
      #      $rdf->assert_resource( $uri, 'foaf:Agent', $co );
      #      $rdf->assert_literal( $co, 'foaf:name', $val );
      $rdf->assert_resource( $ruri, 'dct:creator', $uri );
    },
    'Series'   => undef,
    'Synopsis' => 'dct:description',
    'title'    => 'dct:title',
    'chapters' => undef,
  );

  while ( my ( $k, $v ) = each %$rec ) {
    if ( length $v ) {
      my $h = $mapper{$k};
      if ( defined $h ) {
        if   ( ref $h ) { $h->($v) }
        else            { $rdf->assert_literal( $ruri, $h, $v ) }
      }
    }
  }
}

# vim:ts=2:sw=2:sts=2:et:ft=perl


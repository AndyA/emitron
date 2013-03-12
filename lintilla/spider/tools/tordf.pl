#!/usr/bin/env perl

use strict;
use warnings;

use JSON;
use Path::Class;
use RDF::Helper;
use RDF::Trine;
use RDF::Helper::Constants qw(:dc);
use RDF::Trine::Serializer::RDFXML;

use constant IDMAP => 'stash/id.json';
use constant DB    => 'stash/db.json';

my ( %fountain, %stash );

my $db = load_json(DB);
my $idm
 = -e IDMAP
 ? load_json(IDMAP)
 : {
  seq => 0,
  id  => {} };

my %done = ();    # ids we've described

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
  res   => 'http://bbc.co.uk/res#',                         # scratch
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

sub make_agent {
  my ( $cat, $thing ) = @_;
  my $uri = resource_uri( $cat, $thing );
  unless ( $done{$uri} ) {
    my $co = $rdf->new_bnode;
    $rdf->assert_resource( $uri, 'foaf:Agent', $co );
    $rdf->assert_literal( $co, 'foaf:name', $thing );
    $done{$uri}++;
  }
  return $uri;
}

sub load_rec {
  my $rec = shift;

  my $id = delete $rec->{'Film ID'};
  die "Undefined ID" unless defined $id;
  my $ruri = resource_uri( media => $id );

  #  print "$ruri\n";

  $rec->{title} = words( delete @{$rec}{ 'Article', 'Title' } );

  my %mapper = (
    'Choreographer' => sub {
      for my $ent ( split /\s*,\s*/, $_[0] ) {
        next if $ent =~ /^\s*$/;
        $rdf->assert_resource( $ruri, 'res:choreographer',
          make_agent( director => $ent ) );
      }
    },
    'Date'     => 'dct:date',
    'Director' => sub {
      for my $ent ( split /\s*,\s*/, $_[0] ) {
        next if $ent =~ /^\s*$/;
        $rdf->assert_resource( $ruri, 'res:director',
          make_agent( director => $ent ) );
      }
    },
    'Full credits'       => undef,
    'Full synopsis'      => undef,    # chapters
    'Minutes'            => undef,
    'Part'               => undef,
    'Production Company' => sub {
      $rdf->assert_resource( $ruri, 'dct:creator',
        make_agent( company => $_[0] ) );
    },
    'Series' => sub {
      $rdf->assert_resource( $ruri, 'res:series',
        make_agent( series => $_[0] ) );
    },
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

sub resource_uri {
  my ( $cat, $thing ) = @_;
  my $id = get_id( $cat, $thing );
  return "/$id#id";
}

sub get_id {
  my ( $cat, $thing ) = @_;

  my $id = $idm->{id}{$cat}{$thing};
  unless ( defined $id ) {
    $id = $idm->{id}{$cat}{$thing} = ++$idm->{seq};
    save_json( IDMAP, $idm );
  }
  return $id;
}

sub trim {
  my $s = shift;
  s/^\s+//, s/\s+$// for $s;
  return $s;
}

# Strangely asymmetric application of utf8 seems to DRT. Shrug.

sub load_json { JSON->new->utf8->decode( scalar file( $_[0] )->slurp ) }

sub save_json {
  my $out = file( $_[0] );
  $out->parent->mkpath;
  my $fh = $out->openw;
  $fh->binmode(':utf8');
  print $fh JSON->new->pretty->encode( $_[1] );
}

# vim:ts=2:sw=2:sts=2:et:ft=perl


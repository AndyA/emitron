package RDF::FourStore::Namespace;

use Moose;

=head1 NAME

RDF::FourStore::Namespace - Namespace stuff for 4store

=cut

1;

has ns => (
  traits  => ['Hash'],
  is      => 'rw',
  isa     => 'HashRef[Str]',
  default => sub { {} },
  handles => {
    known => 'keys',
    add   => 'set',
    get   => 'get',
  },
);

my %NS = (
  'activ'     => 'http://www.bbc.co.uk/ontologies/activity/',
  'dc'        => 'http://purl.org/dc/elements/1.1/',
  'dcterms'   => 'http://purl.org/dc/terms/',
  'event'     => 'http://purl.org/NET/c4dm/event.owl#',
  'foaf'      => 'http://xmlns.com/foaf/0.1/',
  'mo'        => 'http://purl.org/ontology/mo/',
  'owl'       => 'http://www.w3.org/2002/07/owl#',
  'po'        => 'http://purl.org/ontology/po/',
  'rdf'       => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
  'rdfs'      => 'http://www.w3.org/2000/01/rdf-schema#',
  'skos'      => 'http://www.w3.org/2008/05/skos#',
  'time'      => 'http://www.w3.org/2006/time#',
  'timeline'  => 'http://purl.org/NET/c4dm/timeline.owl#',
  'wgs84_pos' => 'http://www.w3.org/2003/01/geo/wgs84_pos#',
  'xsd'       => 'http://www.w3.org/2001/XMLSchema#',
);

sub BUILD {
  my $self = shift;
  while ( my ( $k, $v ) = each %NS ) {
    $self->add( $k, $v );
  }
}

sub to_declaration {
  my ( $self, $pfx, @sfx ) = @_;
  my $ns = $self->ns;
  return join '', map { "$pfx $_: <$ns->{$_}>@sfx\n" } sort keys %$ns;
}

sub to_sparql { shift->to_declaration('PREFIX') }
sub to_turtle { shift->to_declaration( '@prefix', '.' ) }

# vim:ts=2:sw=2:sts=2:et:ft=perl

package RDF::FourStore;

use Moose;

use RDF::FourStore::Namespace;

use Carp qw( croak );
use LWP::UserAgent;
use XML::LibXML::XPathContext;
use XML::LibXML;

=head1 NAME

RDF::FourStore - A Perl API for 4store

=cut

our $VERSION = '0.01';

has endpoint => ( isa => 'Str', is => 'ro', required => 1 );
has softlimit => ( isa => 'Num', is => 'rw' );

has ua => (
  isa     => 'LWP::UserAgent',
  is      => 'ro',
  lazy    => 1,
  default => sub { LWP::UserAgent->new }
);

has ns => (
  isa     => 'RDF::FourStore::Namespace',
  is      => 'ro',
  lazy    => 1,
  default => sub { RDF::FourStore::Namespace->new }
);

sub _decode {
  my ( $self, $xml ) = @_;

  my @rs  = ();
  my $dom = XML::LibXML->load_xml( string => $xml );
  my $xp  = XML::LibXML::XPathContext->new($dom);
  $xp->registerNs( s => 'http://www.w3.org/2005/sparql-results#' );

  for my $res ( $xp->findnodes('/s:sparql/s:results/s:result') ) {
    my $rec = {};
    for my $bi ( $xp->findnodes( 's:binding', $res ) ) {
      my $key = $bi->getAttribute('name');
      my @v   = $bi->nonBlankChildNodes;
      if ( $key && @v ) {
        $rec->{$key} = {
          type  => $v[0]->nodeName,
          value => $v[0]->textContent,
        };
      }
    }
    push @rs, $rec;
  }

  return \@rs;
}

sub _dkv { defined $_[1] ? ( $_[0] => $_[1] ) : () }

sub select {
  my ( $self, $query ) = @_;
  my $req = {
    query => join( "\n", $self->ns->to_sparql, $query ),
    _dkv( 'soft-limit' => $self->softlimit ),
  };
  my $resp
   = $self->ua->post( $self->endpoint . '/sparql/', Content => $req );
  croak $resp->status_line if $resp->is_error;
  return $self->_decode( $resp->content );
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

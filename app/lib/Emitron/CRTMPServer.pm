package Emitron::CRTMPServer;

use strict;
use warnings;

use JSON;
use MIME::Base64;
use URI::Escape;

use base qw( Emitron::HTTPClient );

use accessors::ro qw( uri );

=head1 NAME

Emitron::CRTMPServer - CRTMPServer API

=cut

sub new {
  my ( $class, %args ) = @_;
  return bless {%args}, $class;
}

sub api {
  my ( $self, $verb, $args ) = @_;
  my $uri = join '/', $self->uri, $verb,
   map { uri_escape( $_ ) } %{ $args || {} };
  my $resp = $self->ua->get( $uri );
  die $resp->status_line if $resp->is_error;
  return decode_json $resp->content;
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

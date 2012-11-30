package Emitron::CRTMPServer;

use Moose;

use JSON;
use MIME::Base64;
use URI::Escape;

with qw( Emitron::HTTPClient );

has uri => ( isa => 'Str', is => 'ro' );

=head1 NAME

Emitron::CRTMPServer - CRTMPServer API

=cut

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

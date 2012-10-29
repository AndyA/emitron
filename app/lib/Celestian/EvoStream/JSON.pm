package NewStream::EvoStream::JSON;

use strict;
use warnings;

use base qw( Exporter );

our @EXPORT_OK = qw( detox_json );

sub detox_json($);

=head1 NAME

NewStream::EvoStream::JSON - JSON helpers

=cut

sub detox_json($) {
  my $data = shift;
  if ( my $ref = ref $data ) {

    return $$data
     if UNIVERSAL::can( $data, 'isa' )
     && $data->isa( 'JSON::XS::Boolean' );

    return { map { $_ => detox_json( $data->{$_} ) } keys %$data }
     if 'HASH' eq $ref;

    return [ map { detox_json( $_ ) } @$data ]
     if 'ARRAY' eq $ref;
  }
  return $data;
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

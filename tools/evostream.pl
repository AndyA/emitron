#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;
use JSON::XS;
use LWP::UserAgent;
use MIME::Base64;

my $evo = evo->new( host => 'localhost' );
print Dumper($evo->api('version'));

sub evo::new {
  my ( $class, %args ) = @_;
  return bless {%args}, $class;
}

sub evo::ua {
  my $self = shift;
  return $self->{ua} ||= LWP::UserAgent->new;
}

sub evo::api {
  my ( $self, $function, %args ) = @_;
  my $uri = 'http://' . $self->{host} . ':7777/' . $function;
  if ( keys %args ) {
    my $args = join ' ', map { "$_=$args{$_}" } sort keys %args;
    $uri .= '?params=' . encode_base64( $args, '' );
  }
  my $resp = $self->ua->get( $uri );
  die $resp->status_line if $resp->is_error;
  return decode_json $resp->content;
}

# vim:ts=2:sw=2:sts=2:et:ft=perl


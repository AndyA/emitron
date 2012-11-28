package Data::JSONPatch;

use strict;
use warnings;

use Carp qw( confess croak );
use Storable qw( dclone );

use base qw( Exporter );

our @EXPORT = qw( json_patch json_patched );

=head1 NAME

Data::JSONPatch - Apply a JSONPatch to a data structure

=head1 VERSION

This document describes Data::JSONPath version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

  use Data::JSONPath;
  
=head1 DESCRIPTION

  http://goessner.net/articles/JsonPath/
  http://tools.ietf.org/html/draft-pbryan-json-patch-00

=head1 INTERFACE 

=cut

sub _at_path {
  my ( $data, $cb, $k, @path ) = @_;
  return $cb->( $data, $k ) unless @path;
  croak "JSONPath refers to a non-existant path"
   unless defined $data && ref $data;
  return _at_path( $data->{$k}, $cb, @path ) if 'HASH'  eq ref $data;
  return _at_path( $data->[$k], $cb, @path ) if 'ARRAY' eq ref $data;
  confess( "I don't know how to handle a " . ref $data );
}

=head2 C<< json_patch >>

  json_patch($data_a, $diff);

=cut

sub json_patch {
  my ( $orig, $patch ) = @_;
  my $data = { '$' => $orig };
  for my $p ( @$patch ) {
    my @path = map { split /\./ }
     grep { defined } @{$p}{ 'path', 'element' };
    if ( $p->{op} eq 'add' ) {
      my $v = $p->{value};
      _at_path(
        $data,
        sub {
          my ( $data, $k ) = @_;
          if ( 'HASH' eq ref $data ) { $data->{$k} = $v }
          elsif ( 'ARRAY' eq ref $data ) { splice $data, $k, 0, $v }
          else                           { confess }
        },
        @path
      );
    }
    elsif ( $p->{op} eq 'remove' ) {
      _at_path(
        $data,
        sub {
          my ( $data, $k ) = @_;
          if    ( 'HASH'  eq ref $data ) { delete $data->{$k} }
          elsif ( 'ARRAY' eq ref $data ) { splice $data, $k, 1 }
          else                           { confess }
        },
        @path
      );
    }
    else {
      croak "Bad op: $p->{op}";
    }
  }
  return $data->{'$'};
}

=head2 C<< json_patched >>

  my $data_b = json_patched($data_a, $diff);

=cut

sub _clone {
  return dclone $_[0] if ref $_[0];
  return $_[0];
}

sub json_patched {
  my ( $orig, $patch ) = @_;
  return json_patch( _clone( $orig ), $patch );
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

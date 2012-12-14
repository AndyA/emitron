package Data::JSONPatch;

use strict;
use warnings;

use Carp qw( confess croak );
use Storable qw( dclone );

use Data::JSONVisitor;

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

=head2 C<< json_patch >>

  json_patch($data_a, $diff);

=cut

sub json_patch {
  my ( $orig, $patch ) = @_;
  my $jp = Data::JSONPatch->new( $orig );
  $jp->patch( $patch );
  return $jp->data;
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

sub new {
  my $self = bless {}, shift;
  $self->data( @_ ) if @_;
  $self;
}

sub data {
  my $self = shift;
  return $self->{p}->data unless @_;
  $self->{p} = Data::JSONVisitor->new( @_ );
  $self;
}

sub patch_path {
  my ( $self, $p ) = @_;
  join '.',
   ( exists $p->{path}    ? ( $p->{path} )    : () ),
   ( exists $p->{element} ? ( $p->{element} ) : () );
}

sub patch {
  my ( $self, $jp ) = @_;
  for my $pp ( @$jp ) {
    my $path = $self->patch_path( $pp );
    if ( $pp->{op} eq 'add' ) {
      my $v = $pp->{value};
      $self->{p}->each(
        $path,
        sub {
          my ( undef, undef, $elt, $key ) = @_;
          if ( 'ARRAY' eq ref $elt ) { splice @$elt, $key, 0, $v }
          elsif ( 'HASH' eq ref $elt ) { $elt->{$key} = $v }
          else                         { die }
        }
      );
    }
    elsif ( $pp->{op} eq 'remove' ) {
      $self->{p}->each(
        $path,
        sub {
          my ( undef, undef, $elt, $key ) = @_;
          if ( 'ARRAY' eq ref $elt ) { splice @$elt, $key, 1 }
          elsif ( 'HASH' eq ref $elt ) { delete $elt->{$key} }
          else                         { die }
        }
      );
    }
    else { croak "Bad op: ", $pp->{op} }
  }
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

package Data::JSONVisitor;

use strict;
use warnings;

use Data::JSONPath;

=head1 NAME

Data::JSONVisitor - Visit a data structure using a JSONPath

=head1 VERSION

This document describes Data::JSONVisitor version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

  use Data::JSONPath;
  
=head1 DESCRIPTION

  http://goessner.net/articles/JsonPath/
  http://tools.ietf.org/html/draft-pbryan-json-patch-00

=head1 INTERFACE 

=cut

sub new {
  my ( $class, $data ) = @_;
  return bless { data => { '$' => $data } }, $class;
}

sub data { shift->{data}{'$'} }

sub upgrade {
  my ( $class, $obj ) = @_;
  return $obj if UNIVERSAL::can( $obj, 'isa' ) && $obj->isa( $class );
  return $class->new( $obj );
}

sub _set {
  my ( $obj, $k, $v ) = @_;
  if    ( 'ARRAY' eq ref $obj ) { $obj->[$k] = $v }
  elsif ( 'HASH'  eq ref $obj ) { $obj->{$k} = $v }
  else                          { die }
}

sub _get {
  my ( $obj, $k ) = @_;
  return $obj->[$k] if 'ARRAY' eq ref $obj;
  return $obj->{$k} if 'HASH'  eq ref $obj;
  return;
}

sub iter {
  my ( $self, $path, $autoviv ) = @_;
  my @p  = Data::JSONPath->upgrade( $path )->path;
  my @pi = ();
  my @pk = ();
  my @pd = ( $self->{data} );
  my ( $ipos, $vpos ) = ( 0, 0 );
  my $k;

  return sub {
    while ( $vpos < @p ) {
      while ( $ipos <= $vpos ) {
        $pi[$ipos] = $p[$ipos]{iter}( $pd[$ipos] );
        $ipos++;
      }
      if ( defined( $k = $pi[$vpos]->() ) ) {
        return if !defined $pd[$vpos];
        $pk[ $vpos++ ] = $k;
        my $pdo = $pd[ $vpos - 1 ];
        $pd[$vpos] = _get( $pdo, $k );
        if ( $autoviv && !defined $pd[$vpos] ) {
          if ( $k =~ /^\d+$/ && 'HASH' eq ref $pdo && 0 == keys %$pdo )
          {
            # Convert empty parent to array
            _set(
              $pd[ $vpos - 2 ],
              $pk[ $vpos - 2 ],
              $pd[ $vpos - 1 ] = []
            );
          }
          _set( $pd[ $vpos - 1 ], $k, $pd[$vpos] = {} ) if $vpos < @p;
        }
      }
      else {
        return if $vpos == 0;
        $ipos = $vpos--;
      }
    }
    my $key = $pk[ $vpos - 1 ];
    my $ctx = $pd[ $vpos - 1 ];
    $key *= 1 if 'ARRAY' eq ref $ctx;
    my $rv = [ join( '.', @pk ), $pd[$vpos], $ctx, $key ];
    $vpos--;
    return $rv;
  };
}

sub each {
  my ( $self, $path, $cb, $autoviv ) = @_;
  my $ii = $self->iter( $path, $autoviv );
  while ( my $i = $ii->() ) {
    $cb->( @$i );
  }
}

sub set {
  my ( $self, $path, $value ) = @_;
  $self->each( $path, sub { _set( $_[2], $_[3], $value ); }, 1 );
}

sub get {
  my ( $self, $path ) = @_;
  my $v;
  $self->each( $path, sub { $v = $_[1] } );
  return $v;
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

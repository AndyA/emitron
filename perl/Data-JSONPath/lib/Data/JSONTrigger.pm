package Data::JSONTrigger;

use strict;
use warnings;

use Storable qw( dclone );

use Data::JSONDiff;
use Data::JSONVisitor;

use base qw( Data::JSONPatch );

=head1 NAME

Data::JSONTrigger - Fire triggers on data changes

=head1 VERSION

This document describes Data::JSONTrigger version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

  use Data::JSONTrigger;
  
=head1 DESCRIPTION

  http://goessner.net/articles/JsonPath/
  http://tools.ietf.org/html/draft-pbryan-json-patch-00

=head1 INTERFACE 

=cut

sub new {
  my ( $class, $data ) = @_;
  my $self = bless { handler => [] }, $class;
  $self->SUPER::data( $data || {} );
}

sub _visit {
  my ( $obj, $cb, @path ) = @_;
  return unless defined $obj;

  if ( ref $obj ) {
    if ( 'ARRAY' eq ref $obj ) {
      for my $i ( 0 .. $#$obj ) {
        _visit( $obj->[$i], $cb, @path, $i );
      }
      return;
    }

    if ( 'HASH' eq ref $obj && keys %$obj ) {
      for my $i ( sort keys %$obj ) {
        _visit( $obj->{$i}, $cb, @path, $i );
      }
      return;
    }
  }

  $cb->( join( '.', @path ), $obj );
}

sub _set_bit {
  my ( $v, $path, $bit ) = @_;
  $v->each(
    $path,
    sub {
      my ( undef, undef, $ctx, $key ) = @_;
      if    ( 'ARRAY' eq ref $ctx ) { $ctx->[$key] |= $bit }
      elsif ( 'HASH'  eq ref $ctx ) { $ctx->{$key} |= $bit }
    },
    1
  );
}

sub change_set {
  my ( $self, $jp ) = @_;
  my $list = Data::JSONVisitor->new( {} );
  my $orig = Data::JSONVisitor->new( dclone $self->data );

  for my $pp ( @$jp ) {
    my $path = $self->patch_path( $pp );
    if ( $pp->{op} eq 'add' ) {
      _visit( $pp->{value}, sub { _set_bit( $list, $_[0], 2 ) },
        $path );
    }
    elsif ( $pp->{op} eq 'remove' ) {
      $self->{p}->each(
        $path,
        sub {
          _visit( $_[1], sub { _set_bit( $list, $_[0], 1 ) }, $path );
        }
      );
    }
    else { die }
  }
  return { orig => $orig, list => $list };
}

sub on {
  my ( $self, $path, $cb, $group ) = @_;
  push @{ $self->{handler} },
   {
    path  => $path,
    pp    => Data::JSONPath->upgrade( $path ),
    cb    => $cb,
    group => $group || 'global',
   };
  $self;
}

sub _is_like {
  my ( $h, $like ) = @_;
  for my $prop ( qw( path group ) ) {
    return 1 if exists $like->{$prop} && $like->{$prop} eq $h->{$prop};
  }
  return;
}

sub off {
  my ( $self, %like ) = @_;
  my $hh = [ grep { !_is_like( $_, \%like ) } @{ $self->{handler} } ];
  $self->{handler} = $hh;
  $self;
}

sub fire {
  my $self = shift;
  for my $h ( @{ $self->{handler} } ) {
    $h->{cb}( @_ ) if $h->{pp}->match( $_[0] );
  }
  $self;
}

sub trigger_set {
  my ( $self, $cs ) = @_;
  for my $h ( @{ $self->{handler} } ) {
    $cs->{list}->each(
      $h->{pp},
      sub {
        my ( $p, $v, $c, $k ) = @_;
        my $flags = 0;
        _visit( $v, sub { $flags |= $_[1] } );
        if ( $flags ) {
          my $before = $cs->{orig}->get( $p );
          my $after  = $self->{p}->get( $p );
          $h->{cb}
           ->( $p, $before, $after, @{ $h->{pp}->capture( $p ) } )
           if defined $before || defined $after;
        }
      }
    );
  }
  $self;
}

sub patch {
  my ( $self, $jp ) = @_;
  my $cs = $self->change_set( $jp );
  $self->SUPER::patch( $jp );
  $self->trigger_set( $cs );
  $self;
}

sub data {
  my $self = shift;
  return $self->SUPER::data unless @_;
  my $data = shift;
  my $diff = json_diff $self->SUPER::data, $data;
  my $cs   = $self->change_set( $diff );
  $self->SUPER::data( $data );
  $self->trigger_set( $cs );
  $self;
}

sub trigger {
  my ( $self, $jp ) = @_;
  $self->trigger_set( $self->change_set( $jp ) );
  $self;
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

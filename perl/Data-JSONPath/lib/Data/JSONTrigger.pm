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

sub _is_like {
  my ( $h, $like ) = @_;
  for my $prop ( qw( path group ) ) {
    return 1 if exists $like->{$prop} && $like->{$prop} eq $h->{$prop};
  }
  return;
}

sub _cook_handler {
  my $h = shift;
  return $h if exists $h->{limit};
  return $h unless exists $h->{path};
  my $hh = {%$h};
  $hh->{limit} = '*';
  @{$hh}{ 'limit', 'path' } = ( $1, $2 )
   if $hh->{path} =~ /^([-\+\*])(.*)/;
  return $hh;
}

sub on {
  my ( $self, $path, $cb, $group ) = @_;
  my $h = _cook_handler(
    {
      path  => $path,
      cb    => $cb,
      group => $group || 'global',
    }
  );
  $h->{pp} = Data::JSONPath->upgrade( $h->{path} );
  push @{ $self->{handler} }, $h;
  $self;
}

sub off {
  my ( $self, %like ) = @_;
  my $lk = _cook_handler( \%like );
  my $hh = [ grep { !_is_like( $_, $lk ) } @{ $self->{handler} } ];
  $self->{handler} = $hh;
  $self;
}

sub fire {
  my ( $self, $path, @args ) = @_;
  my $lk = _cook_handler( { path => $path } );
  for my $h ( @{ $self->{handler} } ) {
    $h->{cb}( $lk->{path}, @args ) if $h->{pp}->match( $lk->{path} );
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
          my $b = $cs->{orig}->get( $p );
          my $a = $self->{p}->get( $p );
          use Data::Dumper;
          $h->{cb}->( $p, $b, $a, @{ $h->{pp}->capture( $p ) } )
           if ( $h->{limit} eq '+' && ( !defined $b && defined $a ) )
           || ( $h->{limit} eq '-' && ( defined $b && !defined $a ) )
           || ( $h->{limit} eq '*' && ( defined $b || defined $a ) );
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

sub has_trigger {
  my $self = shift;
  return scalar @{ $self->{handler} };
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

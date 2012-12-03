package Emitron::Core;

use Moose;

use Carp qw( croak );

use Emitron::Logger;
use Emitron::MessageDespatcher;

extends 'Exporter';

our @EXPORT = qw( em );

has root => ( isa => 'Str', is => 'ro', default => '/tmp/emitron' );

has [ '_d_msg', '_d_event' ] => (
  isa     => 'Emitron::MessageDespatcher',
  is      => 'ro',
  default => sub { Emitron::MessageDespatcher->new }
);

=head1 NAME

Emitron::Core - Emitron app runner

=cut

Emitron::Logger->level( Emitron::Logger->DEBUG );

{
  my ( $EMITRON );

  sub import {
    my $class = shift;
    $EMITRON ||= $class->new( @_ );
  }

  sub em { $EMITRON }
}

sub _d_ns {
  my ( $self, $ns ) = @_;
  return $self->_d_msg   if $ns eq 'm';
  return $self->_d_event if $ns eq 'e';
  croak "Namespace must be 'e' or 'm'";
}

sub _on {
  my ( $self, $name, $handler, $group ) = @_;
  croak "Missing namespace: $name" unless $name =~ /^(\w+):(.*)$/;
  my ( $ns, $key ) = ( $1, $2 );
  $self->_d_ns( $ns )->on( $key, $handler, $group );
}

sub on {
  my $self = shift;
  my $name = shift;
  for my $n ( 'ARRAY' eq ref $name ? @$name : $name ) {
    $self->_on( $n, @_ );
  }
  $self;
}

sub off {
  my ( $self, %like ) = @_;
}

sub run {
  my $self = shift;
  print "That's all folks\n";
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

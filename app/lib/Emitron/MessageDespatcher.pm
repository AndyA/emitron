package Emitron::MessageDespatcher;

use strict;
use warnings;

use Emitron::Logger;

=head1 NAME

Emitron::MessageDespatcher - Despatch messages

=cut

sub new {
  my $class = shift;
  return bless { @_, h => {} }, $class;
}

sub on {
  my ( $self, $type, $handler ) = @_;
  push @{ $self->{h}{$type} }, $handler;
  return $self;
}

sub despatch {
  my ( $self, $msg ) = @_;

  my @h = @{ $self->{h}{ $msg->type } ||= [] };
  unless ( @h ) {
    debug 'Got unhandled message: ', $msg;
    return;
  }
  $_->( $msg ) for @h;
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

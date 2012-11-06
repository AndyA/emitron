package Emitron::Model::Watched;

use strict;
use warnings;

use IPC::GlobalEvent qw( eventwait eventsignal );

use base qw( Emitron::Model::Diff );

=head1 NAME

Emitron::Model::Watched - A model with an associated global event

=cut

sub _evfile { shift->_obj_name( 'event' ) }

sub commit {
  my ( $self, @args ) = @_;
  my $rev = $self->SUPER::commit( @args );
  eventsignal( $self->_evfile, $rev ) if defined $rev;
  return $rev;
}

sub wait {
  my ( $self, $serial, $timeout ) = @_;
  return eventwait( $self->_evfile, $serial, $timeout );
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

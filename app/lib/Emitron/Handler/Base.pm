package Emitron::Handler::Base;

use strict;
use warnings;

use Emitron::Logger;

=head1 NAME

Emitron::Handler::Base - A message handler

=cut

sub new {
  my $class = shift;
  return bless {@_}, $class;
}

sub subscribe {
  my ( $self, $desp ) = @_;
  die;
}

sub get_handler {
  my ( $self, $verb ) = @_;
  return unless $verb =~ /^(\w+)$/;
  my $method = "_handle_$1";
  return $self->can( $method );
}

sub handle {
  my ( $self, $verb ) = @_;
  return
      $self->get_handler( $verb )
   || $self->get_handler( 'UNKNOWN' )
   || sub {
    warning "Unhandled verb: $verb (no UNKNOWN handler)";
   };
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

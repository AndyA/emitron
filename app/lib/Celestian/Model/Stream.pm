package Celestian::Model::Stream;

use strict;
use warnings;

use Celestian::Logger;

use base qw( Celestian::Model::Base );

use constant kind => 'stream';

use accessors::ro qw( evo id );

=head1 NAME

Celestian::Model::Stream - A stream

=cut

sub query {
  my $self = shift;
  return $self->evo->get_stream_info( id => $self->id )->{data};
}

sub _static {
  my $self = shift;
  return $self->{_static} ||= $self->query;
}

sub name { shift->_static->{name} }
sub type { shift->_static->{type} }

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

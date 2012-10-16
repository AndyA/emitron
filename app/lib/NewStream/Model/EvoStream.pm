package NewStream::Model::EvoStream;

use strict;
use warnings;

use NewStream::Logger;

use base qw( NewStream::Model::Base );

use constant kind => 'evostream';

use accessors::ro qw( evo );

=head1 NAME

NewStream::Model::EvoStream - An EvoStream instance

=cut

sub on_added {
  my $self = shift;
  my $app  = shift;
  $app->on( 'tick', sub { $self->on_tick } );
}

sub on_tick {
  debug( 'Tick!' );
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

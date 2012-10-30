package Emitron::Model::Diff;

use strict;
use warnings;

use Data::Patch qw( data_diff );

use base qw( Emitron::Model );

=head1 NAME

Emitron::Model::Diff - Add diff support to model

=cut

sub diff {
  my ( $self, $ra, $rb ) = @_;
  my $da = $self->checkout( $ra );
  return unless defined $da;
  my $db = $self->checkout( $rb );
  return unless defined $db;
  return data_diff( $da, $db );
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

package Emitron::Config;

use strict;
use warnings;

use YAML qw( LoadFile );

=head1 NAME

Emitron::Config - The dreaded config system. Gotta have one.

=cut

sub new {
  my $class = shift;
  return bless {@_}, $class;
}

sub load {
  my ( $self, $file ) = @_;
  die if $self->{C};
  $self->{C} = LoadFile( $file );
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

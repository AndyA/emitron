package Emitron::BackOff;

use strict;
use warnings;

=head1 NAME

Emitron::BackOff - Exponential backoff

=cut

use accessors::ro qw( base rise max current );

sub new {
  my $class = shift;
  my $self  = bless {
    @_,
    base => 1,
    rise => 2**0.5,
    max  => 60,
  }, $class;
  $self->{current} = $self->{base};
  return $self;
}

sub good {
  my $self = shift;
  return $self->{current} = $self->base;
}

sub bad {
  my $self = shift;
  my $next = $self->current * $self->rise;
  my $max  = $self->max;
  $next = $max if defined $max && $next > $max;
  return $self->{current} = $next;
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

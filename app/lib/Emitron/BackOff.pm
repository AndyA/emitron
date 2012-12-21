package Emitron::BackOff;

use Moose;

=head1 NAME

Emitron::BackOff - Exponential backoff

=cut

has base => ( isa => 'Num', is => 'ro', default => 1 );
has rise => ( isa => 'Num', is => 'ro', default => 2**0.5 );
has max  => ( isa => 'Num', is => 'ro', default => 60 );
has current => ( isa => 'Num', is => 'rw' );

sub BUILD {
  my $self = shift;
  $self->current( $self->base );
}

sub good {
  my $self = shift;
  return $self->current( $self->base );
}

sub bad {
  my $self = shift;
  my $next = $self->current * $self->rise;
  my $max  = $self->max;
  $next = $max if defined $max && $next > $max;
  return $self->current($next);
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

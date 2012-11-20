package Harmless::Stream;

use strict;
use warnings;

use Carp qw( croak );

=head1 NAME

Harmless::Stream - A single bit rate HLS stream

=cut

use accessors::ro qw( filename );

sub new {
  my $class = shift;
  return bless { @_, _runs => [ [] ] }, $class;
}

sub read {
  my $self = shift;

  open my $fh, '<', $self->filename
   or croak "Can't read ", $self->filename, ": $!";

  while ( defined( my $ln = <$fh> ) ) {
    chomp $ln;
    next if $ln =~ /^\s*$/;
    if ( $ln =~ /^#EXT(.*)/ ) {
      # Directive
      my $ext = $1;
      next;
    }
    next if $ln =~ /^#/;
    # Segment URL
  }
}

sub write {
  my $self = shift;
}

sub push_discontinuity {
  my $self = shift;
  push @{ $self->{_runs} }, [];
}

sub push_segment {
  my ( $self, $seg ) = @_;
  push @{ $self->{_runs}[-1] }, $seg;
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

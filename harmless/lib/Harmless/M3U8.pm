package Harmless::M3U8;

use strict;
use warnings;

use Harmless::M3U8::Parser;

use Carp qw( croak );

=head1 NAME

Harmless::M3U8 - An M3U8 file

=cut

sub new {
  my $class = shift;
  return bless { @_, _runs => [ [] ] }, $class;
}

sub read {
  my ( $self, $file ) = @_;
  $self->{_pl} = Harmless::M3U8::Parser->new->parse_file( $file );
}

sub write {
  my $self = shift;
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

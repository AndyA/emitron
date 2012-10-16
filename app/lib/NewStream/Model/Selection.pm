package NewStream::Model::Selection;

use strict;
use warnings;

use Scalar::Util qw( refaddr );

use base qw( NewStream::Model::Base );

=head1 NAME

NewStream::Model::Selection - A selection of objects

=cut

sub _new {
  my ( $class, $base, $filter ) = @_;
  return bless {
    base   => $base,
    filter => $filter,
   },
   $class;
}

sub _select {
  my $self = shift;
  return if exists $self->{_index};
  my $base   = $self->{base};
  my $filter = $self->{filter};
  $base->witheach(
    sub {
      my ( $kind, $obj ) = @_;
      if ( $filter->( $obj ) ) {
        my $ol = $self->{_obj}{$kind} ||= [];
        $self->{_index}{ refaddr $obj } = [ $kind, scalar @$ol ];
        push @$ol, $obj;
      }
    }
  );
}

sub witheach_kind {
  my $self = shift;
  $self->_select;
  return $self->SUPER::witheach_kind( @_ );
}

sub witheach_of {
  my $self = shift;
  $self->_select;
  return $self->SUPER::witheach_of( @_ );
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

package Emitron::Core;

use Moose;

use Carp qw( croak );

use Emitron::Logger;
use Emitron::MessageDespatcher;

has root => ( isa => 'Str', is => 'ro', default => '/tmp/emitron' );
has in_child => (
  isa     => 'Bool',
  is      => 'rw',
  default => 0,
);

has _despatcher => (
  isa     => 'Emitron::MessageDespatcher',
  is      => 'ro',
  default => sub { Emitron::MessageDespatcher->new }
);

=head1 NAME

Emitron::Core - Emitron app runner

=cut

Emitron::Logger->level( Emitron::Logger->DEBUG );

{
  my ( $EMITRON );

  sub import {
    my $class = shift;
    $EMITRON ||= $class->new( @_ );
    {
      my $pkg = caller;
      no strict 'refs';
      *{"${pkg}::em"} = sub { $EMITRON };
    }
  }
}

sub _wrap_handler {
  my ( $self, $handler ) = @_;
  return $handler;
}

sub _on {
  my ( $self, $name, $handler, $group ) = @_;
  if ( UNIVERSAL::can( $name, 'isa' ) && $name->isa( 'IO::Handle' ) ) {
    # Register handle to select on
    return;
  }
  if ( $name =~ /^\$/ ) {
    # JSONPath to trigger on
    return;
  }
  $self->_despatcher->on( $name, $self->_wrap_handler( $handler ),
    $group );
}

sub on {
  my $self = shift;
  my $name = shift;
  for my $n ( 'ARRAY' eq ref $name ? @$name : $name ) {
    $self->_on( $n, @_ );
  }
  $self;
}

sub off {
  my ( $self, %like ) = @_;
}

sub run {
  my $self = shift;

}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

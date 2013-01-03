package ForkPipe::Role::Handler;

use Moose::Role;

=head1 NAME

ForkPipe::Role::Handler - Register handlers

=cut

has _handlers => (
  isa     => 'HashRef[ArrayRef]',
  is      => 'ro',
  default => sub { {} },
);

sub on {
  my ( $self, $verb, $cb ) = @_;
  my $h = $self->_handlers;
  push @{ $h->{$verb} }, $cb;
}

sub trigger {
  my ( $self, $verb, @a ) = @_;
  my $h = $self->_handlers;
  for my $hh ( @{ $h->{$verb} || [] } ) {
    $hh->(@a);
  }
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

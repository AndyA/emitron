package ForkPipe::Role::Handler;

use Moose::Role;

=head1 NAME

ForkPipe::Role::Handler - Register handlers

=cut

has _on => (
  traits  => ['Array'],
  isa     => 'ArrayRef[CodeRef]',
  is      => 'ro',
  default => sub { [] },
  handles => {
    on        => 'push',
    _handlers => 'elements'
  }
);

sub _trigger {
  my ( $self, @a ) = @_;
  for my $hh ( $self->_handlers ) {
    $hh->( @a );
  }
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

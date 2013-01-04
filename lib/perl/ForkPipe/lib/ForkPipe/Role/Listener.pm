package ForkPipe::Role::Listener;

use Moose::Role;

=head1 NAME

ForkPipe::Role::Listener - A listener

=cut

has listener => (
  isa      => 'ForkPipe::Listener',
  is       => 'ro',
  required => 1,
  lazy     => 1,
  default  => sub { ForkPipe::Listener->new },
  handles  => {
    peek            => 'peek',
    add_listener    => 'add',
    remove_listener => 'remove',
  },
);

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

package ForkPipe::Role::Queue;

use Moose::Role;

=head1 NAME

ForkPipe::Role::Queue - A simple message queue

=cut

has _queue => (
  traits  => ['Array'],
  isa     => 'ArrayRef',
  is      => 'rw',
  default => sub { [] },
  handles => {
    _m_put   => 'push',
    _m_get   => 'shift',
    _m_avail => 'count',
  }
);

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

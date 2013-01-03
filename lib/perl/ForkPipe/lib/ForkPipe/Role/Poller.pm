package ForkPipe::Role::Poller;

use Moose::Role;

use Time::HiRes qw( time );

=head1 NAME

ForkPipe::Role::Poller - Add polling

=cut

requires 'peek';

sub poll {
  my $self = shift;

  $self->peek until @_;    # no args => loop forever

  my $deadline = time + shift;

  while () {
    my $now = time;
    last if $now >= $deadline;
    my $elp = $deadline - $now;
    $self->peek( $deadline - $now );
  }

  return;
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

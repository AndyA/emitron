package ForkPipe::Role::Reaper;

use Moose::Role;

use POSIX ":sys_wait_h";

=head1 NAME

ForkPipe::Role::Reaper - Reap child processes

=cut

sub reap {
  my ( $self, $cb ) = @_;
  while () {
    my $kid = waitpid -1, WNOHANG;
    last if $kid <= 0;
    $cb->( $kid, $? );
  }
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

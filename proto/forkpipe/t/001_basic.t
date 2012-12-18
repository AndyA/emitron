#!perl

use strict;
use warnings;
use Test::More;

use ForkPipe;

sub frok(&) {
  my $cb  = shift;
  my $pid = fork;
  defined $pid or die "Fork failed: $!";
  exit $cb->() ? 1 : 0 unless $pid;
  return $pid;
}

sub ork(&@) {
  my ( $cb, $desc ) = @_;
  waitpid &frok( $cb ), 0;
  is $?, 256, $desc;
}

{
  ok my $fp = ForkPipe->new, 'new';
  isa_ok $fp, 'ForkPipe';
  is $fp->_opid, $$, '_opid';

  ork { ForkPipe->new->_opid != $fp->_opid }
  '_opid different in subprocess';

  ok !$fp->in_child, 'not in_child';
  ork { $fp->in_child } 'in_child';

#  if ( my $pid = $fp->fork ) {
#  }
#  else {
#  }
}

done_testing();

# vim:ts=2:sw=2:et:ft=perl


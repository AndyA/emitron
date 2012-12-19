package Emitron::Media::Roles::Forker;

use Moose::Role;

use Emitron::Logger;
use POSIX ":sys_wait_h";

requires 'globals';

=head1 NAME

Emitron::Media::Roles::Forker - Forked workers

=cut

has _kids => (
  isa     => 'ArrayRef',
  is      => 'rw',
  traits  => ['Array'],
  handles => { add_child => 'push' },
  default => sub { [] }
);

sub _fork {
  my ( $self, $cb ) = @_;
  my $pid = fork;
  die "Can't fork: $!" unless defined $pid;
  exit $cb->() unless $pid;
  return $pid;
}

sub fork {
  my $self = shift;
  my $pid  = $self->_fork( @_ );
  $self->add_child( $pid );
  return $pid;
}

sub spawn {
  my ( $self, @cmd ) = @_;
  return $self->fork(
    sub {
      setpgrp( 0, 0 );
      exec @cmd or die "Can't run ", join( ' ', @cmd ), ": $!";
      return 1;
    }
  );
}

sub bash {
  my ( $self, $cmd ) = @_;
  return $self->spawn( $self->globals->bash, -c => $cmd );
}

sub kill_all {
  my $self = shift;

  my @pids = sort { $a <=> $b } splice @{ $self->_kids };
  my $sig = kill -9, @pids;
  warning "Signalled only $sig of ", scalar( @pids ), "\n"
   unless @pids == $sig;
  my @st = ();
  for my $pid ( @pids ) {
    my $got = waitpid $pid, WNOHANG;
    push @st, $? if $got >= 0;
  }
  return @st;
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

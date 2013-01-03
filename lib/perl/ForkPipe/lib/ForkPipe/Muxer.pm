package ForkPipe::Muxer;

use Moose;

use POSIX ":sys_wait_h";
use ForkPipe::Util::Bag;

=head1 NAME

ForkPipe::Muxer - A multiplexer for multiple ForkPipe instances

=cut

with 'ForkPipe::Role::Queue';
with 'ForkPipe::Role::Listener';
with 'ForkPipe::Role::Poller';

has _workers => (
  isa     => 'ForkPipe::Util::Bag',
  is      => 'ro',
  default => sub { ForkPipe::Util::Bag->new },
  handles => {
    add     => 'add',
    remove  => 'remove',
    workers => 'elements',
  }
);

sub on {
  my ( $self, $verb, $cb ) = @_;
  for my $fp ( $self->workers ) {
    $fp->on( $verb, $cb );
  }
}

sub _make_upstream {
  my $self = shift;
  return sub {
    return unless $self->_m_avail;
    return $self->_m_get;
  };
}

sub _worker_for_pid {
  my ( $self, $pid ) = @_;
  # TODO build a map if O(N) bothers you
  for my $fp ( $self->workers ) {
    return $fp if $fp->other_pid == $pid;
  }
  return;
}

sub _reap {
  my $self = shift;
  while () {
    my $kid = waitpid -1, WNOHANG;
    last if $kid <= 0;
    my $st = $?;
    # got kid
    if ( my $fp = $self->_worker_for_pid($kid) ) {
      $self->remove($fp);
      $fp->obituary($st);
    }
  }
}

before peek => sub { shift->_reap };

sub context {
  my $self = shift;
  return (
    listener => $self->listener,
    upstream => $self->_make_upstream
  );
}

sub send {
  my ( $self, $msg ) = @_;
  $self->_m_put($msg);
  $_->engine->send_pending for $self->workers;
}

sub broadcast {
  my ( $self, $msg ) = @_;
  for my $fp ( $self->workers ) {
    $fp->send($msg);
  }
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

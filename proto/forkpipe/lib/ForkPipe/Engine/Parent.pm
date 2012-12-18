package ForkPipe::Engine::Parent;

use Moose;
use Moose::Util::TypeConstraints;

extends 'ForkPipe::Engine::Base';

enum 'WorkerState' => [qw( PENDING READY BUSY )];

has _state => (
  isa     => 'WorkerState',
  is      => 'rw',
  default => 'PENDING'
);

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

=head1 NAME

ForkPipe::Engine::Parent - Parent engine

=cut

sub handle_control {
  my ( $self, $msg ) = @_;
  print "$$ Got $msg\n";
  $self->_state( $msg );
  $self->_send;
}

sub _send {
  my $self = shift;
  # TODO: hook to check for upstream messages
  print "$$ State: ", $self->_state, "\n";
  return unless $self->_m_avail && $self->_state eq 'READY';
  print "$$ Sending message\n";
  $self->msg->send( $self->_m_get );
  $self->_state( 'BUSY' );
  return 1;
}

sub send {
  my ( $self, $msg ) = @_;
  $self->_m_put( $msg );
  $self->_send;
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

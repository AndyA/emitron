package ForkPipe::Engine::Parent;

use Moose;
use Moose::Util::TypeConstraints;

extends 'ForkPipe::Engine::Base';

enum 'WorkerState' => [qw( PENDING READY BUSY DONE )];

with 'ForkPipe::Role::Queue';

has _state => (
  isa     => 'WorkerState',
  is      => 'rw',
  default => 'PENDING'
);

has upstream => (
  isa     => 'CodeRef',
  is      => 'rw',
  lazy    => 1,
  default => sub {
    sub { return }
  }
);

=head1 NAME

ForkPipe::Engine::Parent - Parent engine

=cut

sub handle_control {
  my ( $self, $msg ) = @_;
  $self->_state( defined $msg ? $msg : 'DONE' );
  $self->send_pending;
}

sub is_ready { shift->_state eq 'READY' }

sub _fetch_up { shift->upstream->() }
sub _busy     { shift->_state( 'BUSY' ) }

sub send_pending {
  my $self = shift;

  return unless $self->is_ready;

  # Check our queue...
  if ( $self->_m_avail ) {
    $self->msg->send( $self->_m_get );
    $self->_busy;
    return 1;
  }

  # ...then upstream queue
  if ( defined( my $msg = $self->_fetch_up ) ) {
    $self->msg->send( $msg );
    $self->_busy;
    return 1;
  }

  return;
}

sub send {
  my ( $self, $msg ) = @_;
  $self->_m_put( $msg );
  $self->send_pending;
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

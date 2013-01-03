package ForkPipe::Engine::Base;

use Moose;

use Carp qw( confess carp );

=head1 NAME

ForkPipe::Engine::Base - Base class for engines

=cut

with 'ForkPipe::Role::Handler';
with 'ForkPipe::Role::Listener';
with 'ForkPipe::Role::Poller';

has ['msg', 'ctl'] => (
  isa      => 'ForkPipe::Pipe',
  is       => 'ro',
  required => 1
);

sub BUILD {
  my $self = shift;

  my $li = $self->listener;

  $li->add( $self->msg->rd,
    sub { $self->handle_message( $self->msg->receive ) } );
  $li->add( $self->ctl->rd,
    sub { $self->handle_control( $self->ctl->receive ) } );
}

sub DEMOLISH { shift->unhook }

sub unhook {
  my $self = shift;

  my $li = $self->listener;

  $li->remove( $self->msg->rd );
  $li->remove( $self->ctl->rd );
}

sub handle_message { my $self = shift; $self->trigger( msg => @_ ) }

sub handle_control {
  my ( $self, $msg ) = @_;
  exit unless defined $msg;
  confess "Wasn't expecting a control message";
}

sub stats {
  my $self = shift;
  return {
    ctl => $self->ctl->stats,
    msg => $self->msg->stats
  };
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

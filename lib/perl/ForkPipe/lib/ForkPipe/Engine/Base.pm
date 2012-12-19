package ForkPipe::Engine::Base;

use Moose;

use Carp qw( confess carp );

=head1 NAME

ForkPipe::Engine::Base - Base class for engines

=cut

with 'ForkPipe::Role::Listener', 'ForkPipe::Role::Handler';

has [ 'msg', 'ctl' ] => (
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

sub DEMOLISH {
  my $self = shift;

  my $li = $self->listener;

  $li->remove( $self->msg->rd );
  $li->remove( $self->ctl->rd );
}

sub handle_message { my $self = shift; $self->_trigger( @_ ) }

sub handle_control {
  my ( $self, $msg ) = @_;
  unless ( defined $msg ) {
    carp "Control channel closed";
    return;
  }
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

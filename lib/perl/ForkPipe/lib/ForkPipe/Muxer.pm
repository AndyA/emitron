package ForkPipe::Muxer;

use Moose;

=head1 NAME

ForkPipe::Muxer - A multiplexer for multiple ForkPipe instances

=cut

with 'ForkPipe::Role::Queue', 'ForkPipe::Role::Listener';

has _workers => (
  traits  => ['Array'],
  isa     => 'ArrayRef[ForkPipe]',
  is      => 'rw',
  default => sub { [] },
  handles => {
    add     => 'push',
    workers => 'elements'
  }
);

sub on {
  my ( $self, $cb ) = @_;
  for my $fp ( $self->workers ) {
    $fp->on( sub { $cb->( $_[0], $fp ) } );
  }
}

sub _make_upstream {
  my $self = shift;
  return sub {
    return unless $self->_m_avail;
    return $self->_m_get;
  };
}

sub context {
  my $self = shift;
  return (
    listener => $self->listener,
    upstream => $self->_make_upstream
  );
}

sub send {
  my ( $self, $msg ) = @_;
  $self->_m_put( $msg );
  $_->engine->send_pending for $self->workers;
}

sub broadcast {
  my ( $self, $msg ) = @_;
  for my $fp ( $self->workers ) {
    $fp->send( $msg );
  }
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

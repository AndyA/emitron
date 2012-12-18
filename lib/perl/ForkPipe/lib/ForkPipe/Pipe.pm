package ForkPipe::Pipe;

use Moose;

use Carp qw( croak );
use Storable qw( store_fd fd_retrieve freeze thaw );

use ForkPipe::Listener;

=head1 NAME

ForkPipe::Pipe - A message pipe between two proesses

=cut

with 'ForkPipe::Role::Stats';

has [ 'rd', 'wr' ] => (
  isa      => 'IO::Handle',
  is       => 'ro',
  required => 1
);

sub _raw_read {
  my ( $self, $len ) = @_;
  my $buf = '';

  until ( length $buf == $len ) {
    my $got = sysread $self->rd, $buf, $len - length $buf, length $buf;
    croak "Communication error: $!" unless defined $got;
    return unless length $buf || $got;
  }

  return $buf;
}

sub _raw_write {
  my ( $self, $msg ) = @_;
  my $len  = pack 'N', length( $msg );
  my $data = $len . $msg;
  my $rc   = syswrite $self->wr, $data;
  croak "Communication error: $!"
   unless defined $rc && $rc == length( $data );
  $self->count( write => length( $data ), send => 1 );
}

sub _msg_read {
  my $self = shift;
  my $len = $self->_raw_read( length pack 'N', 0 );
  return unless defined $len;
  my $data = $self->_raw_read( unpack 'N', $len );
  $self->count( read => length( $data ), receive => 1 );
  return $data;
}

sub receive {
  my $self = shift;
  my $msg  = $self->_msg_read;
  return unless defined $msg;
  return thaw( $msg )->[0];
}

sub send {
  my ( $self, $msg ) = @_;
  $self->_raw_write( freeze [$msg] );
  $self->wr->flush;
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

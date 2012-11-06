package Emitron::Message;

use strict;
use warnings;

use Storable qw( store_fd fd_retrieve freeze thaw );

use accessors::ro qw( msg type );

=head1 NAME

Emitron::Message - A message

=cut

sub new {
  my ( $class, $type, $msg ) = @_;
  return bless {
    type => $type,
    msg  => $msg,
  }, $class;
}

sub raw_read {
  my ( $fd, $len ) = @_;
  my $buf = '';

  until ( length $buf == $len ) {
    my $got = sysread $fd, $buf, $len - length $buf, length $buf;
    die "Communication error: $!" unless defined $got;
    return unless length $buf || $got;
  }
  return $buf;
}

sub msg_get_raw {
  my $rdr = shift;
  my $len = raw_read( $rdr, length pack 'N', 0 );
  return unless defined $len;
  return raw_read( $rdr, unpack 'N', $len );
}

sub msg_get {
  my $rdr = shift;
  my $msg = msg_get_raw( $rdr );
  return unless defined $msg;
  return thaw( $msg )->[0];
  #  return fd_retrieve( $rdr )->[0] or die "Message error: $!";
}

sub msg_put_raw {
  my ( $wtr, $msg ) = @_;
  my $len  = pack 'N', length( $msg );
  my $data = $len . $msg;
  my $rc   = syswrite $wtr, $data;
  die "syswrite failed" unless defined $rc && $rc == length( $data );
}

sub msg_put {
  my ( $wtr, $msg ) = @_;

  my $emsg = freeze [$msg];
  msg_put_raw( $wtr, $emsg );
  $wtr->flush;
}

sub send {
  my ( $self, $fh ) = @_;
  msg_put( $fh, { type => $self->type, msg => $self->msg } );
}

sub recv {
  my ( $class, $fh ) = @_;
  my $msg = msg_get( $fh );
  return unless defined $msg;
  return $class->new( $msg->{type}, $msg->{msg} );
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

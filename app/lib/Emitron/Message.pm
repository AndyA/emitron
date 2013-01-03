package Emitron::Message;

use Moose;

use Storable qw( store_fd fd_retrieve freeze thaw );

has msg    => ( is  => 'ro',  required => 1 );
has type   => ( isa => 'Str', is       => 'ro', required => 1 );
has source => ( isa => 'Str', is       => 'ro', default => 'internal' );
has worker => ( isa => 'Num', is       => 'ro', default => sub { $$ } );

=head1 NAME

Emitron::Message - A message

=cut

sub from_raw {
  my ( $class, $raw ) = @_;
  return $raw if UNIVERSAL::can( $raw, 'isa' ) && $raw->isa($class);
  return $class->new(%$raw);
}

sub get_raw {
  { %{ $_[0] } }
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
  my $msg = msg_get_raw($rdr);
  return unless defined $msg;
  return thaw($msg)->[0];
}

sub msg_put_raw {
  my ( $wtr, $msg ) = @_;
  my $len  = pack 'N', length($msg);
  my $data = $len . $msg;
  my $rc   = syswrite $wtr, $data;
  die "syswrite failed" unless defined $rc && $rc == length($data);
}

sub msg_put {
  my ( $wtr, $msg ) = @_;
  my $emsg = freeze [$msg];
  msg_put_raw( $wtr, $emsg );
  $wtr->flush;
}

sub send {
  my ( $self, $fh ) = @_;
  msg_put( $fh, {%$self} );
}

sub recv {
  my ( $class, $fh ) = @_;
  my $msg = msg_get($fh);
  return unless defined $msg;
  return bless $msg, $class;
}

sub is_safe { shift->source eq 'internal' }

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

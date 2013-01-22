package Dynatron::Client;

use Carp qw( croak );
use IO::Socket;
use JSON;
use Moose;

=head1 NAME

Dynatron::Client - A Dynatron client

=cut

has host => ( isa => 'Str', is => 'ro', default => 'localhost' );
has port => ( isa => 'Int', is => 'ro', default => 6809 );

has _conn => (
  is      => 'ro',
  lazy    => 1,
  default => sub {
    my $self = shift;
    print "Making socket\n";
    my $sock = IO::Socket::INET->new(
      PeerAddr => $self->host,
      PeerPort => $self->port
    );
    defined $sock or croak $!;
    return $sock;
  }
);

sub send {
  my ( $self, $msg ) = @_;
  my $conn = $self->_conn;
  my $json = encode_json $msg;
  my $pay  = join "\n", length($json), $json;
  defined $conn->syswrite($pay) || croak $!;
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

package Emitron::App;

use strict;
use warnings;

use Emitron::Message;
use Emitron::Worker;
use Emitron::Runner;

=head1 NAME

Emitron::App - The Emitron app.

=cut

sub new {
  my $class = shift;
  return bless {@_}, $class;
}

sub run {
  my $self = shift;

  my @w = map { make_worker() } 1 .. 3;
  my $emr = Emitron::Runner->new( workers => \@w );
  for ( 1 .. 5 ) {
    $emr->enqueue(
      Emitron::Message->new( message => { id => $_, touched => 0 } ) );
  }
  $emr->run;
}

sub make_worker {
  my $ttl = int( rand( 10 ) + 3 );
  return sub {
    my ( $get, $wtr ) = @_;
    while ( my $msg = $get->() ) {
      die if --$ttl <= 0;
      sleep rand() * 3;
      my $data = $msg->msg;
      $data->{touched}++;
      print "[$$] Processed $data->{id} ($data->{touched})\n";
      Emitron::Message->new( message => $data )->send( $wtr );
    }
  };
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

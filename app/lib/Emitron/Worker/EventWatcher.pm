package Emitron::Worker::EventWatcher;

use Moose;

use Emitron::Logger;

extends qw( Emitron::Worker::Base );

has queue => ( isa => 'Emitron::Model', is => 'ro', required => 1 );

=head1 NAME

Emitron::Worker::EventWatcher - Listen for events from web app

=cut

sub run {
  my $self = shift;

  my $queue = $self->queue;
  my $first = $queue->earliest;
  my $rev   = defined $first ? $first - 1 : undef;
  my $ser   = 0;

  while () {
    my $nrev = $queue->revision;
    if ( defined $rev ) {
      for my $r ( $rev + 1 .. $nrev ) {
        my $msg = $queue->checkout( $r );
#        $self->post_message(
#          type    => 'message',
#          msg     => $msg,
#          source  => 'api',
#          cleanup => $r
#        ) if defined $msg;
      }
    }
    $rev = $nrev;
    $ser = $queue->wait( $ser, 10000 );
  }
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

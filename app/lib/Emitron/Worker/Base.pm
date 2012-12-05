package Emitron::Worker::Base;

use Moose;

use Emitron::App;
use Emitron::Listener;
use Emitron::Logger;
use Emitron::Message;
use IO::Select;
use Time::HiRes qw( time );

has em => (
  isa     => 'Emitron::App',
  is      => 'ro',
  lazy    => 1,
  default => sub {
    Emitron::App->em;
  },
  handles => [
    'model', 'queue', 'event', 'despatcher',
    'peek',  'poll',  'post_event'
  ]
);

has [ '_reader', '_writer' ] => ( isa => 'IO::Handle', is => 'rw' );

=head1 NAME

Emitron::Worker::Base - A worker

=cut

sub start {
  my ( $self, $rdr, $wtr ) = @_;
  $self->_reader( $rdr );
  $self->_writer( $wtr );
  $self->{selev}  = IO::Select->new( $self->event->fileno );
  $self->{evn}    = $self->event->revision;
  $self->run;
}

sub _signal_ready {
  # TODO how does this signalling method interact with other
  # inputs we might want to listen for?
  shift->post_message( type => 'signal.state', msg => 'READY' );
}

sub handle_messages {
  my $self = shift;
  $self->em->add_listener(
    $self->_reader,
    sub {
      my $fn  = shift;
      my $msg = Emitron::Message->recv( $fn );
      debug "Handling msg ", $msg->type;
      $self->despatcher->despatch( $msg );
      $self->_signal_ready;
    }
  );
  $self->_signal_ready;
}

#sub _poll {
#  my $self = shift;
#  my $nevn = $self->event->poll;
#  return unless defined $nevn;

#  for my $evn ( $self->{evn} + 1 .. $nevn ) {
#    my $ev = $self->event->checkout( $evn );
#    $self->despatch( Emitron::Message->from_raw( $ev ) );
#  }

#  $self->{evn} = $nevn;
#}

sub post_message {
  my ( $self, @msg ) = @_;
  Emitron::Message->new( @msg )->send( $self->_writer );
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

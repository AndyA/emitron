package Emitron::Worker::Base;

use Moose;

use Emitron::Logger;
use Emitron::Message;
use IO::Select;
use Time::HiRes qw( time );

has event => ( isa => 'Emitron::Model', is => 'ro', required => 1 );
has core  => ( isa => 'Emitron::Core',  is => 'ro', required => 1 );

use base qw( Emitron::MessageDespatcher );

=head1 NAME

Emitron::Worker::Base - A worker

=cut

sub start {
  my ( $self, $rdr, $wtr ) = @_;
  $self->{rdr}    = $rdr;
  $self->{wtr}    = $wtr;
  $self->{selmsg} = IO::Select->new( $self->event->fileno, $rdr );
  $self->{selev}  = IO::Select->new( $self->event->fileno );
  $self->{evn}    = $self->event->revision;
  $self->run;
}

sub _select {
  my ( $self, $timeout, $sel ) = @_;
  my $deadline;
  $deadline = time + $timeout / 1000 if defined $timeout;
  while () {
    my @to = ();
    if ( defined $deadline ) {
      my $now = time;
      last if $now >= $deadline;
      @to = ( ( $deadline - $now ) * 1000 );
    }
    for my $fd ( $sel->can_read( @to ) ) {
      return Emitron::Message->recv( $self->{rdr} )
       if $fd == $self->{rdr};
      $self->poll
       if $fd == $self->event->fileno;
    }
  }
  return;
}

sub poll {
  my $self = shift;
  my $nevn = $self->event->poll;
  return unless defined $nevn;

  for my $evn ( $self->{evn} + 1 .. $nevn ) {
    my $ev = $self->event->checkout( $evn );
    $self->despatch( Emitron::Message->from_raw( $ev ) );
  }

  $self->{evn} = $nevn;
}

sub get_message {
  my ( $self, $timeout ) = @_;

  $self->post_message( type => 'signal', msg => 'READY' );

  return $self->_select( $timeout, $self->{selmsg} );
}

sub post_message {
  my ( $self, @msg ) = @_;
  Emitron::Message->new( @msg )->send( $self->{wtr} );
}

sub post_event {
  my ( $self, $name, $ev ) = @_;
  return $self->event->commit(
    {
      type   => 'event',
      name   => $name,
      msg    => $ev,
      source => 'internal',
      worker => $$,
      ts     => time
    }
  );
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

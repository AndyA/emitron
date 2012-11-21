package Emitron::Worker::Base;

use strict;
use warnings;

use Emitron::Message;
use IO::Select;

=head1 NAME

Emitron::Worker::Base - A worker

=cut

sub new {
  my $class = shift;
  return bless {@_}, $class;
}

sub start {
  my ( $self, $rdr, $wtr ) = @_;
  $self->{rdr} = $rdr;
  $self->{wtr} = $wtr;
  $self->{sel} = IO::Select->new( $rdr );
  $self->run;
}

sub get_message {
  my ( $self, @args ) = @_;

  $self->post_message( signal => 'READY' );
  while () {
    return Emitron::Message->recv( $self->{rdr} )
     if $self->{sel}->can_read( @args );
  }
}

sub post_message {
  my ( $self, @msg ) = @_;
  Emitron::Message->new( @msg )->send( $self->{wtr} );
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

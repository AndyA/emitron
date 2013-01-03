package Emitron::Worker::Script;

use Moose;

use Emitron::Logger;
use Emitron::Message;

extends 'Emitron::Worker::Base';

=head1 NAME

Emitron::Worker::Script - The worker wrapper for a script.

=cut

sub run {
  my ( $self, $fp ) = @_;
  $fp->on(
    msg => sub {
      my $msg = shift;
      if ( defined $msg ) {
        my $mm = Emitron::Message->from_raw($msg);
        debug "Handling mm ", $mm->type;
        $self->despatcher->despatch($mm);
      }
      else {
        warning "Undefined msg";
      }
    }
  );
  $self->handle_events;
  $self->poll(10) while 1;
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

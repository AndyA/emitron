package Emitron::Worker::Base;

use Moose;

use Emitron::App;
use Emitron::Message;

has em => (
  isa     => 'Emitron::App',
  is      => 'ro',
  lazy    => 1,
  default => sub {
    Emitron::App->em;
  },
  handles => [
    'model',        'queue', 'event',      'despatcher',
    'peek',         'poll',  'post_event', 'handle_events',
    'add_listener', 'remove_listener'
  ]
);

=head1 NAME

Emitron::Worker::Base - A worker

=cut

sub post_message {
  my ( $self, @msg ) = @_;
  $self->send( Emitron::Message->new(@msg)->get_raw );
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

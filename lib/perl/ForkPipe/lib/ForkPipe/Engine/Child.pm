package ForkPipe::Engine::Child;

use Moose;

extends 'ForkPipe::Engine::Base';

=head1 NAME

ForkPipe::Engine::Child - Child engine

=cut

sub _ready {
  my $self = shift;
  $self->ctl->send('READY');
}

before poll => sub { shift->_ready };

after handle_message => sub { shift->_ready };

sub is_ready { 1 }

sub send {
  my $self = shift;
  $self->msg->send(@_);
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

package ForkPipe::Engine::Child;

use Moose;

extends 'ForkPipe::Engine::Base';

has accept_messages => ( isa => 'Bool', is => 'rw', default => 0 );

=head1 NAME

ForkPipe::Engine::Child - Child engine

=cut

sub _ready {
  my $self = shift;
  $self->ctl->send('READY') if $self->accept_messages;
}

sub is_ready { 1 }
sub state    { 'READY' }

after on => sub {
  my ( $self, $verb, $cb ) = @_;
  $self->accept_messages(1) if $verb eq 'msg';
};

before poll          => sub { shift->_ready };
after handle_message => sub { shift->_ready };

sub send {
  my $self = shift;
  $self->msg->send(@_);
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

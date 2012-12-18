package ForkPipe::Engine::Child;

use Moose;

extends 'ForkPipe::Engine::Base';

=head1 NAME

ForkPipe::Engine::Child - Child engine

=cut

sub _ready {
  my $self = shift;
  print "$$ Setting READY\n";
  $self->ctl->send( 'READY' );
  print "$$ Done setting READY\n";
}

before poll => sub { shift->_ready };

sub send {
  my $self = shift;
  $self->msg->send( @_ );
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

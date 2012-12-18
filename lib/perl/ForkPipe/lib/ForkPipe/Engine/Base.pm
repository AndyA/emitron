package ForkPipe::Engine::Base;

use Moose;

use Carp qw( confess );

=head1 NAME

ForkPipe::Engine::Base - Base class for engines

=cut

has [ 'msg', 'ctl' ] => (
  isa      => 'ForkPipe::Pipe',
  is       => 'ro',
  required => 1
);

has listener => (
  isa      => 'ForkPipe::Listener',
  is       => 'ro',
  required => 1,
  lazy     => 1,
  default  => sub { ForkPipe::Listener->new },
  handles  => [ 'peek', 'poll' ]
);

has on => (
  isa     => 'CodeRef',
  is      => 'rw',
  lazy    => 1,
  builder => '_default_handler'
);

sub BUILD {
  my $self = shift;

  my $li = $self->listener;

  $li->add( $self->msg->rd,
    sub { $self->handle_message( $self->msg->receive ) } );
  $li->add( $self->ctl->rd,
    sub { $self->handle_control( $self->ctl->receive ) } );
}

sub DEMOLISH {
  my $self = shift;

  my $li = $self->listener;

  $li->remove( $self->msg->rd );
  $li->remove( $self->ctl->rd );
}

sub handle_message { my $self = shift; $self->on->( @_ ) }

sub _default_handler {
  sub {
    my $msg = shift;
    eval 'require Data::Dumper';
     Data::Dumper->new( [$msg] )->Indent( 2 )->Quotekeys( 0 )
     ->Useqq( 1 )->Terse( 1 )->Dump;
  };
}

sub handle_control {
  my ( $self, $msg ) = @_;
  confess "Wasn't expecting a control message";
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

package ForkPipe::Listener;

use Moose;

use IO::Select;
use Time::HiRes qw( time );

=head1 NAME

ForkPipe::Listener - Select on multiple handles

=cut

has _sel => (
  isa     => 'IO::Select',
  is      => 'ro',
  lazy    => 1,
  default => sub { IO::Select->new },
  handles => ['remove']
);

sub add {
  my $self = shift;
  $self->_sel->add( [@_] );
}

sub _poll {
  my ( $self, @args ) = @_;
  for my $rdy ( $self->_sel->can_read( @args ) ) {
    my ( $fh, $cb, @args ) = @$rdy;
    $cb->( $fh, @args );
  }
}

sub peek { shift->_poll( 0 ) }

sub poll {
  my ( $self, $timeout ) = @_;
  my $deadline;
  $deadline = time + $timeout if defined $timeout;
  while () {
    if ( defined $deadline ) {
      my $now = time;
      last if $now >= $deadline;
      $self->_poll( $deadline - $now );
    }
    else {
      $self->_poll();
    }
  }
  return;
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

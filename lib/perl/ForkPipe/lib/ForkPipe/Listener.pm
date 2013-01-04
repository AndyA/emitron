package ForkPipe::Listener;

use Moose;

use IO::Select;
use Time::HiRes qw( time );

=head1 NAME

ForkPipe::Listener - Select on multiple handles

=cut

with 'ForkPipe::Role::Stats';

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

sub peek {
  my ( $self, $timeout ) = @_;
  for my $rdy ( $self->_sel->can_read( $timeout || 0 ) ) {
    my ( $fh, $cb, @args ) = @$rdy;
    $cb->( $fh, @args );
    $self->count( handled => 1 );
  }
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

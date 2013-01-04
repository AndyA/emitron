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

sub BUILD {
  my $self = shift;
  print "[$$] New listener: $self\n";
}

sub _get_fileno {
  my $fh = shift;
  return $fh->fileno if UNIVERSAL::can( $fh, 'can' ) && $fh->can('fileno');
  return "$fh";
}

sub _handles {
  my $self = shift;
  return join ', ', map { _get_fileno( $_->[0] ) } $self->_sel->handles;
}

sub add {
  my $self = shift;
  print "[$$] Adding handle to listener $self\n";
  $self->_sel->add( [@_] );
  print "[$$] ", $self->_handles, "\n";
}

sub peek {
  my ( $self, $timeout ) = @_;
  print "[$$] peek\n";
  print "[$$] ", $self->_handles, "\n";
  for my $rdy ( $self->_sel->can_read( $timeout || 0 ) ) {
    my ( $fh, $cb, @args ) = @$rdy;
    $cb->( $fh, @args );
    $self->count( handled => 1 );
  }
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

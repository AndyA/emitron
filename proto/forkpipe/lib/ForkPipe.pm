package ForkPipe;

use Moose;

use Carp qw( croak );
use IO::Handle;

use ForkPipe::Engine::Child;
use ForkPipe::Engine::Parent;
use ForkPipe::Pipe::Child;
use ForkPipe::Pipe::Parent;

our $VERSION = '0.01';

has _opid => ( isa => 'Num', is => 'ro', default => sub { $$ } );

has '_engine' => (
  isa     => 'ForkPipe::Engine::Base',
  is      => 'rw',
  handles => [ 'send', 'peek', 'poll' ]
);

=head1 NAME

ForkPipe - Fork and talk

=cut

sub in_child { shift->_opid != $$ }

sub _make_pipes {
  my ( $self, $count ) = @_;
  my @h = ();
  for ( 1 .. $count ) {
    my ( $rd, $wr ) = ( IO::Handle->new, IO::Handle->new );
    pipe $rd, $wr or croak "Can't create pipe: $!\n";
    push @h, $rd, $wr;
  }
  return @h;
}

sub fork {
  my $self = shift;

  my @p = $self->_make_pipes( 4 );

  my $pid = fork;
  croak "Fork failed: $!" unless defined $pid;

  if ( $pid ) {
    # Parent
    close $_ for @p[ 1, 2, 5, 6 ];

    $self->_engine(
      ForkPipe::Engine::Parent->new(
        ctl => ForkPipe::Pipe::Parent->new( wr => $p[3], rd => $p[0] ),
        msg => ForkPipe::Pipe::Parent->new( wr => $p[7], rd => $p[4] )
      )
    );
  }
  else {
    close $_ for @p[ 0, 3, 4, 7 ];

    $self->_engine(
      ForkPipe::Engine::Child->new(
        ctl => ForkPipe::Pipe::Child->new( wr => $p[1], rd => $p[2] ),
        msg => ForkPipe::Pipe::Child->new( wr => $p[5], rd => $p[6] )
      )
    );

    # Don't execute any END blocks
    use POSIX '_exit';
    eval q{END { _exit 0 }};
  }

  return $pid;
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl
## Please see file perltidy.ERR

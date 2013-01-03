package ForkPipe;

use Moose;

use Carp qw( croak );
use IO::Handle;

use ForkPipe::Engine::Child;
use ForkPipe::Engine::Parent;
use ForkPipe::Pipe;
use ForkPipe::Pipe;

our $VERSION = '0.01';

has _opid => ( isa => 'Num', is => 'ro', default => sub { $$ } );

has 'engine' => (
  isa     => 'ForkPipe::Engine::Base',
  is      => 'rw',
  handles => ['send', 'peek', 'poll', 'on', 'stats']
);

has listener => ( isa => 'ForkPipe::Listener', is => 'ro' );
has upstream => ( isa => 'CodeRef',            is => 'ro' );

BEGIN {
  no strict 'refs';
  *{'_log'} = eval 'require Term::ANSIColor'
   ? sub {
    my ( $self, $msg ) = @_;
    my $col = $self->in_child ? 'yellow' : 'cyan';
    print Term::ANSIColor::colored( "[$$] $msg", $col ), "\n";
   }
   : sub {
    my ( $self, $msg ) = @_;
    my $where = $self->in_child ? "CHILD $$" : "PARENT";
    print "[$where] $msg\n";
   };
}

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

sub _attr {
  my %a = @_;
  map { $_ => $a{$_} } grep { defined $a{$_} } keys %a;
}

sub fork {
  my $self = shift;

  my @p = $self->_make_pipes(4);

  my $pid = fork;
  croak "Fork failed: $!" unless defined $pid;

  unless ($pid) {
    close $_ for @p[0, 3, 4, 7];

    # We don't pass our listener to the child. If we have an explicit
    # listener it's intended for parent use only.
    $self->engine(
      ForkPipe::Engine::Child->new(
        ctl => ForkPipe::Pipe->new( wr => $p[1], rd => $p[2] ),
        msg => ForkPipe::Pipe->new( wr => $p[5], rd => $p[6] )
      )
    );

    # Don't execute any END blocks
    use POSIX '_exit';
    eval q{END { _exit 0 }};
    return;
  }

  # Parent
  close $_ for @p[1, 2, 5, 6];

  $self->engine(
    ForkPipe::Engine::Parent->new(
      _attr(
        listener => $self->listener,
        upstream => $self->upstream
      ),
      ctl => ForkPipe::Pipe->new( wr => $p[3], rd => $p[0] ),
      msg => ForkPipe::Pipe->new( wr => $p[7], rd => $p[4] ),
    )
  );

  return $pid;
}

sub log {
  my $self = shift;
  my $msg = join '', @_;
  $self->_log($_) for split /\n/, $msg;
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

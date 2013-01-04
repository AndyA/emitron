package ForkPipe;

use Moose;

use Carp qw( croak );
use IO::Handle;

use ForkPipe::Engine::Child;
use ForkPipe::Engine::Parent;
use ForkPipe::Pipe;
use ForkPipe::Pipe;

our $VERSION = '0.01';

with 'ForkPipe::Role::Reaper';

has _opid => ( isa => 'Num', is => 'ro', default => sub { $$ } );

has other_pid => (
  isa    => 'Num|Undef',
  is     => 'rw',
  writer => '_set_other_pid'
);

has 'engine' => (
  isa     => 'ForkPipe::Engine::Base|Undef',
  is      => 'rw',
  handles => ['send', 'peek', 'poll', 'on', 'stats', 'trigger', 'state']
);

has listener => (
  isa    => 'ForkPipe::Listener',
  is     => 'ro',
  reader => '_listener',
);

has upstream => ( isa => 'CodeRef', is => 'ro' );

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

sub _reap {
  my $self = shift;
  $self->reap(
    sub {
      my ( $pid, $st ) = @_;
      $self->obituary($st) if $pid == $self->other_pid;
    }
  );
}

before peek => sub { shift->_reap };

sub obituary {
  my ( $self, $status ) = @_;
  $self->trigger( child => { status => $? } );
  $self->engine->unhook;
  $self->engine(undef);
  $self->_set_other_pid(undef);
}

sub fork {
  my $self = shift;

  my @p = $self->_make_pipes(4);

  # inherited by child, overwritten in parent
  $self->_set_other_pid( $self->_opid );
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
  $self->_set_other_pid($pid);

  $self->engine(
    ForkPipe::Engine::Parent->new(
      _attr(
        listener => $self->_listener,
        upstream => $self->upstream
      ),
      ctl => ForkPipe::Pipe->new( wr => $p[3], rd => $p[0] ),
      msg => ForkPipe::Pipe->new( wr => $p[7], rd => $p[4] ),
    )
  );

  return $pid;
}

sub spawn {
  my ( $self, $cb, @args ) = @_;
  my $pid = $self->fork;
  return $pid if $pid;
  $cb->(@args);
  exit;
}

sub log {
  my $self = shift;
  my $msg = join '', @_;
  $self->_log($_) for split /\n/, $msg;
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

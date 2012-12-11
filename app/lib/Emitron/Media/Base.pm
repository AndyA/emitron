package Emitron::Media::Base;

use Moose;

use Emitron::Logger;
use Emitron::Types;

=head1 NAME

Emitron::Media::Base - Media handlers base class

=cut

has name => ( isa => 'Name', is => 'ro', required => 1 );

has programs => (
  isa     => 'Emitron::Media::Programs',
  is      => 'ro',
  default => sub { Emitron::Media::Programs->new }
);

has globals => (
  isa     => 'Emitron::Media::Globals',
  is      => 'ro',
  default => sub { Emitron::Media::Globals->new }
);

has _tmp_dir => (
  isa     => 'File::Temp::Dir',
  is      => 'ro',
  lazy    => 1,
  default => sub { File::Temp->newdir( TEMPLATE => 'emXXXXX' ) }
);

has tmp_dir => (
  isa     => 'Str',
  is      => 'ro',
  lazy    => 1,
  default => sub { shift->_tmp_dir->dirname }
);

has _kids => (
  isa     => 'ArrayRef',
  is      => 'rw',
  traits  => ['Array'],
  handles => { add_child => 'push' },
  default => sub { [] }
);

sub _fork {
  my ( $self, $cb ) = @_;
  my $pid = fork;
  die "Can't fork: $!" unless defined $pid;
  exit $cb->() unless $pid;
  return $pid;
}

sub fork {
  my $self = shift;
  my $pid  = $self->_fork( @_ );
  $self->add_child( $pid );
  return $pid;
}

sub spawn {
  my ( $self, @cmd ) = @_;
  return $self->fork(
    sub {
      setpgrp( 0, 0 );
      #      debug "Running ", join ' ', @cmd;
      exec @cmd or die "Can't run ", join( ' ', @cmd ), ": $!";
      return 1;
    }
  );
}

sub bash {
  my ( $self, $cmd ) = @_;
  return $self->spawn( $self->programs->bash, -c => $cmd );
}

sub kill_all {
  my $self = shift;

  my @pids = sort { $a <=> $b } splice @{ $self->_kids };
  my $sig = kill -9, @pids;
  warning "Signalled only $sig of ", scalar( @pids ), "\n"
   unless @pids == $sig;
  my @st = ();
  for my $pid ( @pids ) {
    my $got = waitpid $pid, 0;
    push @st, $? if $got >= 0;
  }
  return @st;
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

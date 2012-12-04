package Emitron::Worker;

use Moose;
use Moose::Util::TypeConstraints;

use Carp qw( croak );

use Emitron::App;
use Emitron::Message;
use IO::Handle;
use IO::Select;

enum 'WorkerState' => [qw( PENDING READY BUSY )];

has pid    => ( isa => 'Num',        is => 'rw', writer => '_pid', );
has reader => ( isa => 'IO::Handle', is => 'rw', writer => '_reader', );
has writer => ( isa => 'IO::Handle', is => 'rw', writer => '_writer', );

has state => ( isa => 'WorkerState', is => 'rw' );

has worker => (
  isa      => 'Emitron::Worker::Base',
  is       => 'ro',
  required => 1,
);

=head1 NAME

Emitron::Worker - Represents a worker within the master process

=cut

sub BUILD {
  my $self = shift;

  my ( $my_rdr, $my_wtr, $child_rdr, $child_wtr )
   = map { IO::Handle->new } 1 .. 4;

  pipe $child_rdr, $my_wtr
   or croak "Can't create write pipe: $!";

  pipe $my_rdr, $child_wtr
   or croak "Can't create read pipe: $!";

  my $pid = fork;
  croak "Fork failed: $!" unless defined $pid;

  if ( !$pid ) {
    close $_ for $my_rdr, $my_wtr;

    # Don't execute any END blocks
    use POSIX '_exit';
    eval q{END { _exit 0 }};

    Emitron::App->em->in_child( 1 );

    $self->worker->start( $child_rdr, $child_wtr );

    close $_ for $child_rdr, $child_wtr;
    exit;
  }

  # Parent
  close $_ for $child_rdr, $child_wtr;

  $self->_pid( $pid );
  $self->_reader( $my_rdr );
  $self->_writer( $my_wtr );
  $self->state( 'PENDING' );
}

sub is_ready { 'READY' eq shift->state }

sub send {
  my ( $self, $msg ) = @_;
  $msg->send( $self->writer );
  $self->state( 'BUSY' );
}

sub signal {
  my ( $self, $msg ) = @_;
  $self->state( $msg->msg ) if $msg->type eq 'signal';
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

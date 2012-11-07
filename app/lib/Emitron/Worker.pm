package Emitron::Worker;

use strict;
use warnings;

use Carp qw( croak );
use Emitron::Message;
use IO::Handle;
use IO::Select;

use accessors::ro qw( pid reader writer );

=head1 NAME

Emitron::Worker - A worker process

=cut

sub new {
  my ( $class, $worker ) = @_;

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

    my $sel     = IO::Select->new( $child_rdr );
    my $get_msg = sub {
      Emitron::Message->new( signal => 'READY' )->send( $child_wtr );
      while () {
        return Emitron::Message->recv( $child_rdr ) if $sel->can_read;
      }
    };

    $worker->run( $get_msg, $child_wtr );

    close $_ for $child_rdr, $child_wtr;
    exit;
  }

  # Parent
  close $_ for $child_rdr, $child_wtr;
  return bless {
    pid    => $pid,
    reader => $my_rdr,
    writer => $my_wtr,
    state  => 'PENDING',
   },
   $class;
}

sub state {
  my $self = shift;
  return $self->{state} unless @_;
  return $self->{state} = shift;
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

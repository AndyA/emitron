package Emitron::Worker::ModelWatcher;

use Moose;

use Data::JSONTrigger;
use Emitron::Logger;
use Emitron::Model::Watched;

extends qw( Emitron::Worker::Base );

has _trigger => (
  isa     => 'Data::JSONTrigger',
  is      => 'ro',
  lazy    => 1,
  default => sub { Data::JSONTrigger->new }
);

has _revision => ( isa => 'Num', is => 'rw' );

=head1 NAME

Emitron::Worker::ModelWatcher - Watch the model, fire messages on interesting changes

=cut

sub run {
  my $self = shift;

  info "Model watcher starting";

  my $model = $self->em->model;

  my $rev = $model->revision;
  $self->_trigger->data( $model->checkout( $rev ) );

  while () {
    my $nrev = $model->wait( $rev, 10 );
    if ( $nrev ne $rev ) {
      debug "Model updated to $nrev";
      $self->_revision( $nrev );
      $self->_trigger->data( $model->checkout( $rev = $nrev ) );
    }
  }
}

sub _make_signal_name {
  my $self = shift;
  'signal.model.' . ( ++$self->{_next_signal} );
}

sub listen {
  my ( $self, $path ) = @_;
  my $sig = $self->_make_signal_name;
  info "Listen on changes to $path and fire $sig";
  $self->_trigger->on(
    $path,
    sub {
      my ( $p, $b, $a ) = @_;
      debug "Firing $sig for change to $p (matches $path)";
      $self->post_message(
        type => $sig,
        msg  => [ $self->_revision, @_ ]
      );
    }
  );
  return $sig;
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

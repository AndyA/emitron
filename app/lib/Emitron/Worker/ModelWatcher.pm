package Emitron::Worker::ModelWatcher;

use Moose;

use Data::JSONTrigger;
use Emitron::Logger;
use Emitron::Model::Watched;

extends qw( Emitron::Worker::Base );

has model => ( isa => 'Emitron::Model', is => 'ro', required => 1 );

has _trigger => (
  isa     => 'Data::JSONTrigger',
  is      => 'ro',
  lazy    => 1,
  default => sub { Data::JSONTrigger->new }
);

=head1 NAME

Emitron::Worker::ModelWatcher - Watch the model, fire messages on interesting changes

=cut

sub run {
  my $self = shift;

  info "Model watcher starting";

  my $model = $self->model;

  my $rev = $model->revision;
  $self->_trigger->data( $model->checkout( $rev ) );

  while () {
    my $nrev = $self->model->wait( $rev, 10000 );
    if ( $nrev ne $rev ) {
      debug "Model updated to $nrev";
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
  $self->_trigger->on( $path,
    sub { $self->post_message( type => $sig, msg => \@_ ) } );
  return $sig;
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

package Emitron::Worker::ModelWatcher;

use Moose;

use Data::JSONTrigger;
use Emitron::Logger;
use Emitron::Model::Watched;

extends qw( Emitron::Worker::Base );

has model => ( isa => 'Emitron::Model', is => 'ro', required => 1 );

=head1 NAME

Emitron::Worker::ModelWatcher - Watch the model, fire messages on interesting changes

=cut

sub run {
  my $self = shift;

  info "Model watcher starting";

  my $model = $self->model;
  $self->install_hooks;

  my $rev = $model->revision;
  $self->trigger->data( $model->checkout( $rev ) );

  while () {
    my $nrev = $self->model->wait( $rev, 10000 );
    if ( $nrev ne $rev ) {
      debug "Model updated to $nrev";
      $self->trigger->data( $model->checkout( $rev = $nrev ) );
    }
  }
}

sub install_hooks {
  my $self = shift;
  my $jt   = $self->trigger;
  $jt->on(
    '$.streams.*.INR.*',
    sub {
      my ( $path, $before, $after, $name, $app ) = @_;
      debug "$path changed ($name, $app), before: ", $before,
       ", after: ", $after;
    }
  );
}

sub trigger {
  my $self = shift;
  return $self->{trigger} ||= Data::JSONTrigger->new;
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

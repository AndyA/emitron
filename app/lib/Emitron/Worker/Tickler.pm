package Emitron::Worker::Tickler;

use Moose;

use Emitron::Logger;
use Emitron::Model::Watched;
use Time::HiRes qw( time );

extends qw( Emitron::Worker::Base );

has every => ( isa => 'Num', is => 'ro', default => 5 );

=head1 NAME

Emitron::Worker::Tickler - Watch the model, fire messages on interesting changes

=cut

sub run {
  my $self = shift;

  info "Tickler starting";

  for ( ;; ) {
    sleep $self->every;
    $self->em->model->transaction(
      sub {
        my ( $m, $rev ) = @_;
        $m->{misc} = { tickle_time => time };
        return $m;
      }
    );
  }
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

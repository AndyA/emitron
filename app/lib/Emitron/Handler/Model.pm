package Emitron::Handler::Model;

use strict;
use warnings;

use Emitron::Logger;

use base qw( Emitron::Handler::Base );

use accessors::ro qw( model );

=head1 NAME

Emitron::Handler::Model - Handler that updates the model

=cut

sub subscribe {
  my ( $self, $desp ) = @_;

  $desp->on(
    crtmpserver => sub {
      my $ev = shift;
      debug "Media server update: ", $ev;
      $self->despatch( $ev->msg );
    }
  );
}

sub despatch {
  my ( $self, $msg ) = @_;
  $self->handle( $msg->{verb} )->( $self, $msg->{data} );
}

sub _handle_UNKNOWN {
  my ( $self, $data ) = @_;
}

sub _handle_listStreams {
  my ( $self, $data ) = @_;

  # Quick and a little dirty
  $self->model->transaction(
    sub {
      my ( $model, $rev ) = @_;
      $model->{streams} = $self->_munge_streams( $data );
      return $model;
    }
  );
}

sub _munge_streams {
  my ( $self, $data ) = @_;
  my $out = {};
  for my $app ( keys %$data ) {
    my $stms = $data->{$app}->{streams} || {};
    for my $stm ( keys %$stms ) {
      my $rec = $stms->{$stm};
      $rec->{name}        = $stm;
      $rec->{application} = $app;
      $out->{$stm}        = $rec;
    }
  }
  return $out;
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

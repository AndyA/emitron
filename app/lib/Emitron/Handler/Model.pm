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
      my $msg = $ev->msg;

      # Quick and a little dirty
      $self->model->transaction(
        sub {
          my ( $data, $rev ) = @_;
          $data->{streams} = $msg->{data};
          return $data;
        }
      );

    }
  );
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

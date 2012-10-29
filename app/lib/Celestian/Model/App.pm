package Celestian::Model::App;

use strict;
use warnings;

use Celestian::Logger;
use Time::HiRes qw( usleep );

use base qw( Celestian::Model::Base );

use constant kind => 'application';

=head1 NAME

Celestian::Model::App - Newstream Application

=cut

sub poll {
  my $self = shift;
  $self->raise( 'tick' );
}

sub run {
  my $self = shift;
  info( 'Celestian starting' );
  while () {
    usleep 500_000;
    eval { $self->poll };
    if ( my $err = $@ ) {
      error( $err );
    }
  }
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

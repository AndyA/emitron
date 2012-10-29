package NewStream::Model::App;

use strict;
use warnings;

use NewStream::Logger;
use Time::HiRes qw( usleep );

use base qw( NewStream::Model::Base );

use constant kind => 'application';

=head1 NAME

NewStream::Model::App - Newstream Application

=cut

sub poll {
  my $self = shift;
  $self->raise( 'tick' );
}

sub run {
  my $self = shift;
  info( 'NewStream starting' );
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

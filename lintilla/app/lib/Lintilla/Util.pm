package Lintilla::Util;

use strict;
use warnings;

use Time::HiRes qw( sleep time );

use base qw( Exporter );

our @EXPORT_OK = qw( wait_for_file );
our %EXPORT_TAGS = ( all => [@EXPORT_OK] );

=head1 NAME

Lintilla::Util - Utility stuff

=cut

sub wait_for_file {
  my ( $name, $timeout ) = @_;
  return $name if -e $name;
  my $deadline = defined $timeout ? time + $timeout : undef;
  until ( defined $deadline && time >= $deadline ) {
    sleep 0.1;
    return $name if -e $name;
  }
  return;
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

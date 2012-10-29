package Emitron::Logger;

use strict;
use warnings;

=head1 NAME

Emitron::Logger - Log output

=cut

use Data::Dumper;
use POSIX qw( strftime );
use Term::ANSIColor;
use Time::HiRes;

BEGIN {
  our @EXPORT = ();
  my %level = (
    FATAL   => 1,
    ERROR   => 2,
    WARNING => 3,
    INFO    => 4,
    DEBUG   => 5,
  );
  while ( my ( $lvl, $code ) = each %level ) {
    no strict 'refs';
    *$lvl = sub { return $code };
    my $meth = lc $lvl;
    push @EXPORT, $meth;
    *$meth = sub { _mention( $code, @_ ) };
  }
  use base qw( Exporter );
}

my @LOGCOLOUR
 = ( undef, 'red on_white', 'red on_white', 'yellow', 'cyan',
  'green', );

my $LOGLEVEL = INFO;

sub level {
  my $class = shift;
  $LOGLEVEL = shift if @_;
  $LOGLEVEL;
}

sub _ts {
  my $now = shift // Time::HiRes::time;
  return join '.', ( strftime '%Y/%m/%d %H:%M:%S', gmtime( $now ) ),
   sprintf( '%06d', $now * 1_000_000 % 1_000_000 );
}

sub _dd {
  my $obj = shift;
  return Data::Dumper->new( [$obj] )->Indent( 2 )->Quotekeys( 0 )
   ->Useqq( 1 )->Terse( 1 )->Dump;
}

sub _mention {
  my $level = shift;
  return if $level > $LOGLEVEL;
  my $msg = join '', map { ref $_ ? _dd( $_ ) : $_ } @_;
  my $ts = _ts;
  print color $LOGCOLOUR[$level] // 'white';
  print "$ts: $_\n" for split /\n/, $msg;
  print color 'reset';
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

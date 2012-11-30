package Emitron::Logger;

use Moose;

=head1 NAME

Emitron::Logger - Log output

=cut

use Data::Dumper;
use POSIX qw( strftime );
use Term::ANSIColor;
use Time::HiRes;

my ( %level, %lname );

BEGIN {
  our @EXPORT = ();
  %level = (
    FATAL   => 1,
    ERROR   => 2,
    WARNING => 3,
    INFO    => 4,
    DEBUG   => 5,
  );
  %lname = reverse %level;
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
 = ( undef, 'white on_red', 'white on_red', 'yellow', 'cyan',
  'green', );

my $LOGLEVEL = INFO;

sub level {
  my $class = shift;
  $LOGLEVEL = shift if @_;
  $LOGLEVEL;
}

sub _ts {
  my $now = shift || Time::HiRes::time;
  return join '.', ( strftime '%Y/%m/%d %H:%M:%S', gmtime( $now ) ),
   sprintf( '%06d', $now * 1_000_000 % 1_000_000 );
}

sub _dd {
  my $obj = shift;
  chomp( my $dd
     = Data::Dumper->new( [$obj] )->Indent( 2 )->Quotekeys( 0 )
     ->Useqq( 1 )->Terse( 1 )->Dump );
  return $dd;
}

sub _mention {
  my $level = shift;
  return if $level > $LOGLEVEL;
  my $msg = join '',
   map { ref $_ ? _dd( $_ ) : defined $_ ? $_ : '(undefined)' } @_;
  my $ts = _ts;
  my $attr = $LOGCOLOUR[$level] || 'white';

  print colored(
    sprintf( '%s %-7s [%5d] %s', $ts, $lname{$level}, $$, $_ ), $attr
   ),
   "\n"
   for split /\n/, $msg;
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib/perl/Harmless/lib";

use Data::Dumper;
use Getopt::Long;
use Harmless::M3U8;
use POSIX qw( strftime );
use Path::Class;
use Storable qw( dclone );
use Time::HiRes qw( sleep time );
use URI;

my ( $in, $out, @extra ) = @ARGV;
die "Syntax: hlsaslive.pl <in.m3u8> <out.m3u8>\n"
 unless defined $out && !@extra;

hlsaslive( $in, $out );

sub debug(@) {
  my $ts = strftime '%Y-%m-%d %H:%M:%S', localtime;
  for my $ln ( split /\n/, join '', @_ ) {
    print "$ts $ln\n";
  }
}

sub expand {
  my @m  = @_;
  my @mx = ();
  for my $mf (@m) {
    my ( $in, $out ) = @$mf;
    my $m3u8 = Harmless::M3U8->new->read($in);
    my @vpl  = @{ $m3u8->vpl };
    if (@vpl) {
      my $br   = 1;
      my @nvpl = ();
      for my $pl (@vpl) {
        ( my $plout = $out ) =~ s/\.m3u8$/.$br.m3u8/;
        $br++;
        my $plin = file( $pl->{uri} )->absolute( file($in)->parent )->relative;
        $pl->{uri} = file($plout)->basename;
        push @mx, [$plin, $plout];
      }
      $m3u8->write($out);
    }
    else {
      push @mx, [$in, $out];
    }
  }
  return @mx;
}

sub mk_seg_iter {
  my $m3u8 = shift;
  return sub { return }
   unless $m3u8->segment_count;
  my @seg = ( @{ $m3u8->seg }, [] );
  return sub {
    my $seg   = shift @{ $seg[0] };
    my $disco = !defined $seg;
    if ($disco) {
      push @$seg, shift @$seg until @{ $seg[0] };
      $seg = shift @{ $seg[0] };
    }
    push @{ $seg[-1] }, $seg;
    return ( $seg, $disco );
  };
}

sub hlsaslive {
  my ( $in, $out ) = @_;
  my @m = expand( [$in, $out] );

  for my $mf (@m) {
    my ( $in, $out ) = @$mf;
    my $m3u8 = Harmless::M3U8->new->read($in);
    push @$mf, mk_seg_iter($m3u8), $m3u8;
    $m3u8->seg( [[]] )->closed(0)->write($out);
  }

  while () {
    my $now = time;
    my $dur = undef;
    for my $mf (@m) {
      my ( $in, $out, $iter, $m3u8 ) = @$mf;
      my ( $seg, $disco ) = $iter->();

      $m3u8->push_discontinuity if $disco;

      $seg->{uri}
       = file( $seg->{uri} )->absolute( file($in)->parent )
       ->relative( file($out)->parent )
       unless $seg->{uri} =~ /^\w+:/;

      debug "$seg->{uri} $seg->{duration}";
      $m3u8->push_segment($seg);

      $dur = $seg->{duration}
       unless defined $dur && $dur < $seg->{duration};

      $m3u8->rotate(100)->write($out);
    }
    sleep $dur - ( time - $now );
  }
}

# vim:ts=2:sw=2:sts=2:et:ft=perl


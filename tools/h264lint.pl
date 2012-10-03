#!/usr/bin/env perl

use strict;
use warnings;

use File::Find;
use Path::Class;
use Getopt::Long;

use constant H264A  => 'h264_analyze';
use constant FFMPEG => 'ffmpeg';

GetOptions() or die;

lint( @ARGV );

sub is_media {
  my $f = shift;
  return unless $f =~ /\.(?:mp4|mov|ts|avi)$/i;
  return 1;
}

sub make_name {
  my ( $in, $ext ) = @_;
  ( my $out = "$in" ) =~ s/\.[^.]+$/.$ext/;
  return $out;
}

sub lint {
  my @obj = @_;
  find {
    wanted => sub {
      return unless -f;
      check_file( $_ ) if is_media( $_ );
    },
    no_chdir => 1
  }, @obj;
}

sub run(@) {
  my @cmd = @_;
  system @cmd and die join( ' ', @cmd ), " failed: $?\n";
}

sub extract_frames {
  my ( $in, $out, $log ) = @_;
  dir( $out )->mkpath;
  run FFMPEG
   . " -i '$in' -r 25 -s 400x224 -f image2 '$out/f%06d.jpeg'"
   . " >> '$log' 2>&1";
}

sub extract_bitstream {
  my ( $in, $out, $log ) = @_;
  run FFMPEG
   . " -y -i '$in' -vcodec copy -an '$out'"
   . " >> '$log' 2>&1";
}

sub check_file {
  my $f      = shift;
  my $h264   = make_name( $f, 'h264' );
  my $frames = make_name( $f, 'frames' );
  my $log    = make_name( $f, 'log' );

  print "$f -> $h264\n";
  extract_bitstream( $f, $h264, $log );
  print "$f -> $frames\n";
  extract_frames( $f, $frames, $log );
}

# vim:ts=2:sw=2:sts=2:et:ft=perl


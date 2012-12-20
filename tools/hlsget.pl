#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../perl/lib/Harmless/lib";

use Data::Dumper;
use Getopt::Long;
use Harmless::M3U8;
use LWP::UserAgent;
use Path::Class;
use URI;

my %O = ( outdir => '.' );

GetOptions( 'outdir:s' => \$O{outdir} ) or die;

hlsget( @ARGV );

sub _local_name {
  my ( $uri, @path ) = @_;
  my @p = split '/', URI->new( $uri )->path;
  my $luri = join '/', @path, @p;
  my $filename = file $O{outdir}, @path, @p;
  return ( $luri, $filename );
}

sub _m3u8_name { ( _local_name( @_ ), 'm3u8' ) }
sub _seg_name  { ( _local_name( @_ ), 'ts' ) }

sub _is_m3u8 {
  shift->content_type =~ m{
    \b application/ (?: x-mpegURL | vnd.apple.mpegurl ) \b
  }xi;
}

sub hlsget {
  my @q = map { [ $_, _m3u8_name( $_ ) ] } @_;
  my $ua = LWP::UserAgent->new;
  URI: while ( my $spec = shift @q ) {
    my ( $uri, $luri, $filename, $type ) = @$spec;
    if ( $type eq 'ts' && -e $filename ) {
      print "$filename already downloaded, skipping\n";
      next URI;
    }
    my $resp = $ua->get( $uri );
    die $resp->status_line if $resp->is_error;
    $filename->parent->mkpath;
    print "$filename <- $uri\n";
    if ( $uri =~ m{\.m3u8$} || _is_m3u8( $resp ) ) {
      my $m3u8 = Harmless::M3U8->new->parse( $resp->content );
      #      print Dumper( $m3u8 );
      for my $pl ( @{ $m3u8->vpl } ) {
        my $nuri = URI->new_abs( $pl->{uri}, $uri );
        my @sn = _m3u8_name( $nuri );
        push @q, [ $nuri, @sn ];
        $pl->{uri} = $sn[0];
      }
      for my $run ( @{ $m3u8->seg } ) {
        for my $seg ( @$run ) {
          my $nuri = URI->new_abs( $seg->{uri}, $uri );
          my @sn = _seg_name( $nuri );
          push @q, [ $nuri, @sn ];
          $seg->{uri} = $sn[0];
        }
      }
      $m3u8->write( $filename );
    }
    else {
      print { file( $filename )->openw } $resp->content;
    }
  }
}

# vim:ts=2:sw=2:sts=2:et:ft=perl


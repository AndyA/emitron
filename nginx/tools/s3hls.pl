#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;
use Harmless::M3U8;
use JSON;
use Net::Amazon::S3;
use Net::Amazon::S3::Client;
use POSIX qw( strftime );
use Path::Class;
use Storable qw( dclone );
use Time::HiRes qw( sleep );

sub debug(@) {
  my $ts = strftime '%Y-%m-%d %H:%M:%S', localtime;
  for my $ln ( split /\n/, join '', @_ ) {
    print "$ts $ln\n";
  }
}

my $config = shift;

my $cfg  = JSON->new->decode( scalar file($config)->slurp );
my $work = dir( $cfg->{hls}{work} );
$work->mkpath;
my $mapf = file( $work, 'map.json' );

my $s3     = Net::Amazon::S3->new( $cfg->{s3}{connect} );
my $s3c    = Net::Amazon::S3::Client->new( s3 => $s3 );
my $bucket = $s3c->bucket( name => $cfg->{s3}{config}{bucket} );

loop();

sub loop {
  my %mtime = ();
  my %brmf  = ();

  my $fmap = load_map();
  $fmap->{id} = strftime '%Y%m%d%H%M%S', gmtime unless exists $fmap->{id};

  my $dirty     = 1;
  my $done_root = 0;

  while () {
    sleep 0.5;
    while ( my ( $tag, $info ) = each %{ $cfg->{hls}{manifests} } ) {
      my $mf = $info->{source};
      eval {
        my @st = stat $mf;
        die "$mf not found\n" unless @st;
        my $mt = $st[9];
        unless ( defined $mtime{$tag} && $mtime{$tag} == $mt ) {
          my $m3u8 = update( $bucket, $fmap, $tag, $mf );
          $brmf{$tag} = { %$info, m3u8 => $m3u8 };
          $mtime{$tag} = $mt;
          $dirty++;
        }
      };
      debug "WARNING: $@" if $@;
    }

    if ($dirty) {
      debug "Saving $mapf";
      eval { save_map($fmap); $dirty = 0; };
      debug "WARNING: $@" if $@;
      unless ( $done_root || keys %brmf < keys %{ $cfg->{hls}{manifests} } ) {
        make_root( $bucket, \%brmf );
        $done_root++;
      }
    }
  }
}

sub make_root {
  my ( $bucket, $brmf ) = @_;
  my $url = sprintf '%s.m3u8', $cfg->{s3}{config}{key};
  my $file = file( $work, 'root.m3u8' );

  my @m3u8 = ('#EXTM3U');

  my %seen = ();
  for my $tag ( $cfg->{hls}{first}, sort keys %$brmf ) {
    next if $seen{$tag}++;
    push @m3u8,
     (sprintf( '#EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=%d',
        $brmf->{$tag}{bandwidth} ),
      $brmf->{$tag}{m3u8}
     );
  }
  my $m3u8 = join "\n", @m3u8, '';
  print { $file->openw } $m3u8;

  if ( $cfg->{s3}{enable} ) {
    my $obj = object( $bucket, mk_key($url), 'application/x-mpegURL', 600 );
    $obj->put_filename($file);
    my $uri = $obj->uri;
    debug "Deployed M3U8 $uri";
  }
}

sub update {
  my ( $bucket, $fmap, $tag, $mf ) = @_;

  my $mfd      = file($mf)->parent;
  my $m3u8     = Harmless::M3U8->new->read($mf);
  my $duration = $m3u8->meta->{EXT_X_TARGETDURATION} || 8;

  my $wbase = dir( $work, $tag );
  $wbase->mkpath;

  my $m3u8_url = "$tag.m3u8";
  my $m3u8_file = file( $work, $m3u8_url );

  my $m3u8out
   = -e $m3u8_file
   ? Harmless::M3U8->new->read($m3u8_file)
   : do { my $m = Harmless::M3U8->new->read($mf); $m->seg( [[]] ); $m };

  my $disco = 0;
  for my $seg ( map { @$_ } @{ $m3u8->seg } ) {
    my $segf = file( $mfd, $seg->{uri} );
    my @st = stat $segf;
    next unless @st;
    my $id = join '-', @st[0, 1];    # dev-ino

    next if exists $fmap->{map}{$segf}{$id};

    my $frag = sprintf '%s-%08d.ts', $fmap->{id}, $fmap->{next}{$tag}++;
    my $frag_url = join '/', $tag, $frag;
    my $frag_file = file( $wbase, $frag );

    debug "$segf -> $frag_file";
    debug "WARNING: $frag_file exists" if -e $frag_file;

    # Mark done before any possible error
    $fmap->{map}{$segf}{$id} = $frag_url;

    link $segf, $frag_file or die "Can't link $segf to $frag_file: $!\n";

    $m3u8out->push_segment( { %$seg, uri => $frag_url } );

    if ( $cfg->{s3}{enable} ) {
      my $obj = object( $bucket, mk_key($frag_url), 'video/MP2T' );
      $obj->put_filename($frag_file);
      my $uri = $obj->uri;
      debug "Deployed segment $uri";
    }
  }

  my $before = m3u8_count($m3u8out);
  $m3u8out->cleanup( $cfg->{hls}{cleanup} || 1000 );
  my $after = m3u8_count($m3u8out);

  $m3u8out->meta->{EXT_X_MEDIA_SEQUENCE}++ if $after != $before;

  $m3u8out->write($m3u8_file);

  if ( $cfg->{s3}{enable} ) {
    my $obj = object( $bucket, mk_key($m3u8_url), 'application/x-mpegURL',
      $duration / 2 );
    $obj->put_filename($m3u8_file);
    my $uri = $obj->uri;
    debug "Deployed M3U8 $uri";
  }

  return $m3u8_url;
}

sub m3u8_count {
  scalar map { @$_ } @{ shift->seg };
}

sub load_map {
  return -e $mapf ? JSON->new->decode( scalar $mapf->slurp ) : {};
}

sub save_map {
  my $fmap = shift;
  my $tmp  = file("$mapf.tmp");
  { print { $tmp->openw } JSON->new->encode($fmap) }
  rename "$tmp", "$mapf" or die "Can't rename $tmp as $mapf: $!";
}

sub mk_key { join '/', $cfg->{s3}{config}{key}, @_ }

sub object {
  my ( $bucket, $key, $mime, $ttl ) = @_;

  my $now = DateTime->now;

  my @args = (
    key           => $key,
    content_type  => $mime,
    acl_short     => 'public-read',
    last_modified => $now,
  );

  if ( defined $ttl ) {
    my $exp = $now->clone;
    $exp->add( seconds => $ttl );
    push @args, ( expires => $exp, );
  }

  return $bucket->object(@args);
}

# vim:ts=2:sw=2:sts=2:et:ft=perl


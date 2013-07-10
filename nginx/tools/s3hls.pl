#!/usr/bin/env perl

use strict;
use warnings;

use Harmless::M3U8;
use JSON;
use Net::Amazon::S3::Client;
use Net::Amazon::S3;
use Path::Class;
use Time::HiRes qw( sleep );
use POSIX qw( strftime );

my $config = shift;

my $cfg  = JSON->new->decode( scalar file($config)->slurp );
my $work = dir( $cfg->{hls}{work} );
$work->mkpath;
my $mapf = file( $work, 'map.json' );

my $s3 = Net::Amazon::S3->new( $cfg->{s3}{connect} );
my $bucket = $s3->bucket( name => $cfg->{s3}{config}{bucket} );

loop();

sub debug(@) {
  my $ts = strftime '%Y-%m-%d %H:%M:%S', localtime;
  for my $ln ( split /\n/, join '', @_ ) {
    print "$ts $ln\n";
  }
}

sub loop {
  my %mtime = ();
  my $fmap  = load_map();
  while () {
    sleep 0.5;
    while ( my ( $tag, $mf ) = each %{ $cfg->{hls}{manifests} } ) {
      eval {
        my @st = stat $mf;
        unless (@st) {
          debug "WARNING: $mf not found";
          next;
        }
        my $mt = $st[9];
        next if defined $mtime{$tag} && $mtime{$tag} == $mt;
        update( $bucket, $fmap, $tag, $mf );
        $mtime{$tag} = $mt;
      };
      if ($@) { debug "WARNING: $@" }
    }
    eval { save_map($fmap) };
    if ($@) { debug "WARNING: $@" }
  }
}

sub update {
  my ( $bucket, $fmap, $tag, $mf ) = @_;

  my $mfd      = file($mf)->parent;
  my $m3u8     = Harmless::M3U8->new->read($mf);
  my $duration = $m3u8->meta->{EXT_X_TARGETDURATION} || 4;
  my @seg = map { file( $mfd, $_->{uri} ) } map { @$_ } @{ $m3u8->seg };

  for my $seq (@seg) {
    print "$seg\n";
  }

=for ref
  my @todo     = ();
  while (@seg) {
    my $seg = pop @seg;
    my $obj = object( $bucket, mk_key( $tag, $seg ), 'video/MP2T' );
    last if $obj->exists;
    unshift @todo, [$seg, $obj];
  }
  for my $todo (@todo) {
    my ( $seg, $obj ) = @$todo;
    #    $obj->put_filename( file( $mfd, $seg ) );
    my $uri = $obj->uri;
    print "Deployed segment $uri\n";
  }

  return deploy_m3u8( $mf, $key, $duration / 2 );
=cut

}

sub load_map {
  return -e $mapf ? JSON->new->decode( scalar $mapf->slurp ) : {};
}

sub save_map {
  my $fmap = shift;
  my $tmp  = file("$mapf.tmp");
  { print { $tmp->openw } JSON->new->encode($fmap) }
  rename "$tmp", "$fmap" or die "Can't rename $tmp as $fmap: $!";
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

sub deploy {
  my ( $bucket, $file, $key, $mime, $ttl ) = @_;
  print "Deploying $file as $key ($mime)\n";
  my $obj = object( $bucket, $key, $mime, $ttl );
  #  $obj->put_filename($file);
  return $obj->uri;
}

sub deploy_m3u8 {
  my ( $bucket, $file, $key, $ttl ) = @_;
  return deploy( $bucket, $file, $key, 'application/x-mpegURL', $ttl );
}

# vim:ts=2:sw=2:sts=2:et:ft=perl


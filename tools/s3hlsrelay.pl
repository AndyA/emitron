#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib/perl/Harmless/lib";

use Data::Dumper;
use Harmless::M3U8;
use JSON;
use LWP::UserAgent;
use Net::Amazon::S3::Client;
use Net::Amazon::S3;
use POSIX qw( strftime );
use Path::Class;
use Storable qw( dclone );
use Time::HiRes qw( sleep time );
use URI;

sub debug(@) {
  my $ts = strftime '%Y-%m-%d %H:%M:%S', localtime;
  for my $ln ( split /\n/, join '', @_ ) {
    print "$ts $ln\n";
  }
}

my $config   = shift;
my $next_tmp = 1;

my $cfg  = JSON->new->decode( scalar file($config)->slurp );
my $work = dir( $cfg->{general}{work} );
$work->mkpath;

my $s3     = Net::Amazon::S3->new( $cfg->{s3}{connect} );
my $s3c    = Net::Amazon::S3::Client->new( s3 => $s3 );
my $bucket = $s3c->bucket( name => $cfg->{s3}{config}{bucket} );

relay( $bucket, @{ $cfg->{relay} } );

wait;

sub relay {
  my ( $bucket, @stm ) = @_;

  for my $stream (@stm) {
    next unless $stream->{enable};
    my ( $path, $id, $ext ) = split_path( $stream->{path} );
    my $m3m = make_m3u8_mapper( $stream->{path} );

    my @leaf = find_leaf(
      $stream->{uri},
      sub {
        my ( $uri, $m3u8 ) = @_;
        my $name = $uri eq $stream->{uri} ? $id . $ext : $m3m->($uri);
        for my $pl ( @{ $m3u8->vpl } ) {
          $pl->{uri} = $m3m->( URI->new_abs( $pl->{uri}, $stream->{uri} ) );
        }
        my $out
         = put_data( $m3u8->format, $bucket, "$path$name",
          'application/x-mpegURL' );
        debug "$uri -> $out\n";
      }
    );

    my $pid = spawn_worker( $bucket, $_, $path, $m3m ) for @leaf;
  }
}

sub tmp_file { file( $cfg->{general}{work}, $next_tmp++ ) }

sub spawn_worker {
  my ( $bucket, $url, $path, $m3m ) = @_;
  my $pid = fork;
  die "Fork failed: $!\n" unless defined $pid;
  return $pid if $pid;
  # FORKED

  my $out = $path . $m3m->($url);
  my $tsm = make_ts_mapper($out);
  debug "worker($url -> $out)";

  my %state = ();
  if ( $cfg->{s3}{enable} ) {
    load_state( $bucket, $out, \%state );
  }

  my $ua = LWP::UserAgent->new;

  while () {
    my $now  = time;
    my $resp = $ua->get($url);
    if ( $resp->is_error ) {
      debug "WARNING: ", $resp->status_line;
      sleep 10;
      next;
    }

    for ( values %state ) { $_ = 'OLD' if $_ eq 'CURRENT' }

    my $m3u8 = Harmless::M3U8->new->parse( $resp->content );
    for my $seg ( map { @$_ } @{ $m3u8->seg } ) {
      my $src  = URI->new_abs( $seg->{uri}, $url );
      my $dst  = $tsm->($src);
      my $dloc = $path . $dst;
      unless ( $state{$dloc} ) {
        my $loc = put_url( $src, $bucket, $dloc, 'video/MP2T' );
        next unless defined $loc;
        debug "$src -> $loc";
      }
      $seg->{uri} = $dst;
      $state{$dloc} = 'CURRENT';
    }

    my $ttl = $m3u8->meta->{EXT_X_TARGETDURATION} / 2;

    if ( $cfg->{s3}{enable} ) {
      my $obj = object( $bucket, $out, 'application/x-mpegURL', $ttl );
      my $tmpf = tmp_file;
      $m3u8->write($tmpf);
      $obj->put_filename($tmpf);
      $tmpf->remove;
      debug "Updated ", $obj->uri;
    }

    my @old = sort grep { $state{$_} eq 'OLD' } keys %state;
    for my $key (@old) {
      my $obj = $bucket->object( key => $key );
      $obj->delete;
      delete $state{$key};
      debug "Removed $key";
    }

    my $sleep = $ttl - ( time - $now );
    $sleep = 0.5 if $sleep < 0.5;
    sleep $sleep;
  }

  exit;
}

sub load_state {
  my ( $bucket, $loc, $state ) = @_;
  my ( $path, $name, undef ) = split_path($loc);
  my $stm = $bucket->list( { prefix => "$path$name" } );
  until ( $stm->is_done ) {
    for my $obj ( $stm->items ) {
      $state->{ $obj->key } = 'CURRENT';
      debug "Found ", $obj->key;
    }
  }
}

sub split_path {
  my $path = shift;
  $path =~ m{^(.*?)([^/]+?)((?:\.[^./]*)?)$} && return ( $1, $2, $3 );
  return ( '', $path, '' );
}

sub make_ts_mapper {
  my ( undef, $id, undef ) = split_path(shift);
  return sub {
    my ( undef, $name, undef ) = split_path shift;
    return "$id/$name.ts";
  };
}

sub make_m3u8_mapper {
  my ( undef, $id, undef ) = split_path(shift);
  my %seen = ();
  my $next = 1;
  return sub {
    my $in = shift;

    return $seen{$in} ||= do { join '.', $id, $next++, 'm3u8' };
  };
}

sub find_leaf {
  my ( $root, $cb ) = @_;
  my $ua   = LWP::UserAgent->new;
  my @q    = ($root);
  my @leaf = ();
  while ( my $url = shift @q ) {
    debug "GET $url";
    my $resp = $ua->get($url);
    # Fatal at this stage - not live yet
    die $resp->status_line if $resp->is_error;
    my $m3u8 = Harmless::M3U8->new->parse( $resp->content );
    my @vpl  = @{ $m3u8->vpl };
    if (@vpl) {
      $cb->( $url, dclone $m3u8 );
      push @q, map { URI->new_abs( $_->{uri}, $root ) } @vpl;
      next;
    }
    push @leaf, $url;
  }
  return @leaf;
}

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

sub put_if_not_exist {
  my ( $cb, $bucket, $key, $mime, $ttl ) = @_;
  debug "PUT $key ($mime)";
  if ( $cfg->{s3}{enable} ) {
    my $obj = object( $bucket, $key, $mime, $ttl );
    unless ( $obj->exists ) {
      my $file = eval { $cb->($obj) };
      if ( my $err = $@ ) {
        debug "WARNING: $err";
        return;
      }
      $obj->put_filename($file);
    }
    return $obj->uri;
  }
  return "http://example.com/$key";
}

sub put_file {
  my ( $file, $bucket, $key, $mime, $ttl ) = @_;
  return put_if_not_exist( sub { $file }, $bucket, $key, $mime, $ttl );
}

sub put_data {
  my ( $data, $bucket, $key, $mime, $ttl ) = @_;

  my ($tmpf);
  my $uri = put_if_not_exist(
    sub {
      $tmpf = tmp_file;
      print { $tmpf->openw } $data;
      return $tmpf;
    },
    $bucket,
    $key,
    $mime,
    $ttl
  );
  $tmpf->remove if $tmpf;
  return $uri;
}

sub put_url {
  my ( $url, $bucket, $key, $mime, $ttl ) = @_;

  my ($tmpf);
  my $uri = put_if_not_exist(
    sub {
      $tmpf = tmp_file;
      my $ua = LWP::UserAgent->new;
      my $resp = $ua->get( $url, ':content_file' => "$tmpf" );
      die $resp->status_line, "\n" if $resp->is_error;
      return $tmpf;
    },
    $bucket,
    $key,
    $mime,
    $ttl
  );
  $tmpf->remove if $tmpf;
  return $uri;
}

# vim:ts=2:sw=2:sts=2:et:ft=perl


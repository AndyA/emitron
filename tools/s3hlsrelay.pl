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

use constant FFMPEG_NON_ATOMIC_HACK => 0;

sub debug(@) {
  my $ts = strftime '%Y-%m-%d %H:%M:%S', localtime;
  my $id = sprintf '%6d', $$;
  for my $ln ( split /\n/, join '', @_ ) {
    print "$ts [$id] $ln\n";
  }
}

my $config   = shift;
my $next_tmp = 1;

my $cfg  = JSON->new->decode( scalar file($config)->slurp );
my $work = dir( $cfg->{general}{work} );
$work->mkpath;

my $bucket = get_bucket();
my $prefix = strftime '%Y%m%d%H%M%S-', gmtime;
relay( $bucket, $prefix, @{ $cfg->{relay} } );

wait;

sub get_bucket {
  my $s3     = Net::Amazon::S3->new( $cfg->{s3}{connect} );
  my $s3c    = Net::Amazon::S3::Client->new( s3 => $s3 );
  my $bucket = $s3c->bucket( name => $cfg->{s3}{config}{bucket} );
  return $bucket;
}

sub relay {
  my ( $bucket, $prefix, @stm ) = @_;

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
      }
    );

    my $pid = spawn_worker( $_, $path, $m3m, $stream, $prefix ) for @leaf;
  }
}

sub tmp_file { file( $cfg->{general}{work}, join '.', $$, $next_tmp++ ) }

sub stream_latest {
  my ( $pla, $plb ) = @_;

  return $plb->segment_index(
    $pla->segment_count + $pla->sequence - $plb->sequence );
}

sub make_stream_window {
  my $rotate = shift;
  debug "Rotation window: $rotate" if defined $rotate;
  my ( $prev, $curr );
  return sub {
    my $next = shift;
    unless ($curr) {
      $curr = dclone $next;
      $curr->seg( [[]] )->closed(0);
      $curr->meta->{EXT_X_MEDIA_SEQUENCE} += $next->segment_count;
    }
    if ($prev) {
      # TODO is ffmpeg failing to update the m3u8 atomically?
      if ( FFMPEG_NON_ATOMIC_HACK
        && $next->segment_count < $prev->segment_count - 2 ) {
        debug "WARNING: segment loss (", $next->segment_count, " < ",
         $prev->segment_count, ")";
        return dclone $curr;
      }
      my $seg = $next->seg;
      my ( $rn, $pos )
       = $next->segment_index(
        $prev->segment_count + $prev->sequence - $next->sequence );
      while ( defined $rn && $rn < @$seg ) {
        $curr->push_discontinuity if $pos == 0 && $rn > 0;
        my $run = $seg->[$rn++];
        $curr->push_segment( @{$run}[$pos .. $#$run] );
        $pos = 0;
      }
    }
    $prev = dclone $next;
    $curr->rotate($rotate) if defined $rotate;
    return dclone $curr;
  };
}

sub make_stream_direct {
  sub { $_[0] }
}

sub spawn_worker {
  my ( $url, $path, $m3m, $stream, $prefix ) = @_;

  my $mode = $stream->{mode} || 'direct';

  my $pid = fork;
  die "Fork failed: $!\n" unless defined $pid;
  return $pid if $pid;
  # FORKED

  my $bucket = get_bucket();
  my $out    = $path . $m3m->($url);
  my $tsm    = make_ts_mapper( $out, $prefix );
  debug "worker($url -> $out)";

  my %state = ();
  if ( $cfg->{s3}{enable} ) {
    debug "Loading state for $out";
    load_state( $bucket, $out, \%state );
    debug "State loaded, ", scalar keys %state, " items found";
  }

  my $filter
   = $mode eq 'direct' ? make_stream_direct()
   : $mode eq 'window' ? make_stream_window( $stream->{window} || 900 )
   :                     die "Bad stream mode: $mode\n";

  my $ua = LWP::UserAgent->new;

  while () {
    eval {
      my $now = time;

      debug "GET $url";
      my $resp = $ua->get($url);
      if ( $resp->is_error ) {
        debug "WARNING: $url: ", $resp->status_line;
        sleep 10;
        next;
      }

      my $m3u8 = $filter->( Harmless::M3U8->new->parse( $resp->content ) );
      my $ttl = ( $m3u8->meta->{EXT_X_TARGETDURATION} || 4 ) / 2;

      if ( $m3u8->segment_count ) {
        $_++ for values %state;
        for my $seg ( map { @$_ } @{ $m3u8->seg } ) {
          my $src  = URI->new_abs( $seg->{uri}, $url );
          my $dst  = $tsm->($src);
          my $dloc = $path . $dst;
          unless ( exists $state{$dloc} ) {
            my $loc = put_url( $src, $bucket, $dloc, 'video/MP2T' );
            next unless defined $loc;
            debug "$src -> $loc";
          }
          $seg->{uri} = $dst;
          $state{$dloc} = 0;
        }

        if ( $cfg->{s3}{enable} ) {
          my $obj = object( $bucket, $out, 'application/x-mpegURL', $ttl );
          my $tmpf = tmp_file;
          $m3u8->write($tmpf);
          $obj->put_filename($tmpf);
          $tmpf->remove;
          debug "Updated ", $obj->uri;
        }

        my @old = sort grep { $state{$_} >= $cfg->{general}{grace} } keys %state;

        @old = splice @old, 0, $cfg->{general}{maxdelete}
         if defined $cfg->{general}{maxdelete};

        for my $key (@old) {
          my $obj = $bucket->object( key => $key );
          $obj->delete;
          delete $state{$key};
          debug "Removed $key";
        }
      }
      else {
        debug "WARNING: empty m3u8: $url";
      }

      my $sleep = $ttl - ( time - $now );
      $sleep = 0.5 if $sleep < 0.5;
      sleep $sleep;
    };
    if ( my $err = $@ ) {
      $err =~ s/\s+/ /g;
      debug "ERROR: $err";
      sleep 5;
    }
  }

  exit;
}

sub load_state {
  my ( $bucket, $loc, $state ) = @_;
  my ( $path, $name, undef ) = split_path($loc);
  my $prefix = "$path$name/";
  debug "Scanning $prefix";
  my $stm = $bucket->list( { prefix => $prefix } );
  until ( $stm->is_done ) {
    for my $obj ( $stm->items ) {
      $state->{ $obj->key } = 0;
    }
  }
}

sub split_path {
  my $path = shift;
  $path =~ m{^(.*?)([^/]+?)((?:\.[^./]*)?)$} && return ( $1, $2, $3 );
  return ( '', $path, '' );
}

sub make_ts_mapper {
  my ( $path, $prefix ) = @_;
  my ( undef, $id, undef ) = split_path($path);
  $prefix ||= '';
  return sub {
    my ( undef, $name, undef ) = split_path shift;
    return "$id/$prefix$name.ts";
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


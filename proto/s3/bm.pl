#!/usr/bin/env perl

use strict;
use warnings;

use Config::Tiny;
use Data::Dumper;
use DateTime;
use Getopt::Long;
use Net::Amazon::S3::Client;
use Net::Amazon::S3;
use POSIX ":sys_wait_h";
use Path::Class;
use Time::HiRes qw( time );

use constant BUCKET => 'thespace-media-live';
use constant DIR    => 'x_emitron_test';

my %O = ( config => glob('~/.s3/the-space-live.ini') );

GetOptions( 'config:s' => \$O{config}, ) or die;

my $cfg = Config::Tiny->read( $O{config} ) or die Config::Tiny->errstr;

upload(@ARGV);

sub upload {
  my %active = ();
  my $id     = 0;
  for my $file (@_) {
    $id++;
    my $size = -s $file;
    my $pid  = fork;
    die "Fork failed: $!\n" unless defined $pid;
    unless ($pid) {
      my $bucket      = make_bucket();
      my $tot_elapsed = 0;
      my $tot_size    = 0;
      for my $frag ( 1 .. 10 ) {
        my $start = time;
        {
          my $key = join '/', DIR, sprintf "%03d.%08d.ts", $id, $frag;
          my $now = DateTime->now;
          my $exp = $now->clone;
          $exp->add( seconds => 4 );
          my $obj = $bucket->object(
            key           => $key,
            content_type  => 'video/MP2T',
            acl_short     => 'public-read',
            last_modified => $now,
            expires       => $exp,
          );
          $obj->put_filename($file);
          my $uri = $obj->uri;
          print "Uploaded $file as $uri\n";
        }
        my $elapsed = time - $start;
        printf "%10d bytes | %4.2f seconds | %10d b/s\n", $size, $elapsed,
         $size / $elapsed;
        $tot_elapsed += $elapsed;
        $tot_size    += $size;
      }
      printf "%10d bytes | %4.2f seconds | %10d b/s\n", $tot_size,
       $tot_elapsed,
       $tot_size / $tot_elapsed;
      exit;
    }
    $active{$pid} = 1;
  }
  while ( keys %active ) {
    my $kid = waitpid -1, 0;
    delete $active{$kid};
  }
}

sub make_bucket {
  my $s3 = Net::Amazon::S3->new(
    { aws_access_key_id     => $cfg->{default}{access_key},
      aws_secret_access_key => $cfg->{default}{secret_key},
      retry                 => 1,
    }
  );

  my $s3c = Net::Amazon::S3::Client->new( s3 => $s3 );

  return $s3c->bucket( name => BUCKET );
}

# vim:ts=2:sw=2:sts=2:et:ft=perl


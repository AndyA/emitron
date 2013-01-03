#!/usr/bin/env perl

use strict;
use warnings;

use Config::Tiny;
use Data::Dumper;
use DateTime;
use Getopt::Long;
use Net::Amazon::S3::Client;
use Net::Amazon::S3;
use Path::Class;

use constant BUCKET => 'thespace-media-live';
use constant DIR    => 'x_emitron_test';
use constant INDEX  => 'index.html';

my %O = ( config => glob('~/.s3cfg') );

GetOptions( 'config:s' => \$O{config}, ) or die;

my $cfg = Config::Tiny->read( $O{config} ) or die Config::Tiny->errstr;

my $s3 = Net::Amazon::S3->new(
  { aws_access_key_id     => $cfg->{default}{access_key},
    aws_secret_access_key => $cfg->{default}{secret_key},
    retry                 => 1,
  }
);

my $s3c = Net::Amazon::S3::Client->new( s3 => $s3 );

my $bucket = $s3c->bucket( name => BUCKET );
my $key = join '/', DIR, INDEX;

{
  my $now = DateTime->now;
  my $exp = $now->clone;
  $exp->add( seconds => 4 );
  print "$now, $exp\n";
  my $idx = $bucket->object(
    key           => $key,
    content_type  => 'text/html',
    acl_short     => 'public-read',
    last_modified => $now,
    expires       => $exp,
  );
  $idx->put_filename( file( DIR, INDEX ) );
  print "URI: ", $idx->uri;
}

{
  my $idx = $bucket->object( key => $key );
  my $v = $idx->get;
  print Dumper($v);
}

# vim:ts=2:sw=2:sts=2:et:ft=perl

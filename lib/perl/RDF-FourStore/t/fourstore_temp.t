#!perl

use strict;
use warnings;

use lib qw( t/lib );

use LWP::UserAgent;
use Path::Class;
use Test::FourStore;
use Test::More;

ok my $fs = Test::FourStore->new, 'new';
like $fs->tmpdir, qr{^/tmp/4s.d}, 'tmp dir';

$fs->clear;

{
  my $db = $fs->make_db;
  ok -d dir( $fs->tmpdir, $db ), "created $db";

  $fs->clear;
  ok !-d dir( $fs->tmpdir, $db ), "deleted $db";
}

{
  my $db = $fs->make_db;
  $fs->with_web_service(
    18394, $db,
    sub {
      my $url    = shift;
      my $status = "$url/status/";
      my $ua     = LWP::UserAgent->new;
      my $resp   = $ua->get("$url/status/");
      ok $resp->is_success, 'http server' or diag $resp->status_line;
    }
  );
}

done_testing();

# vim:ts=2:sw=2:et:ft=perl


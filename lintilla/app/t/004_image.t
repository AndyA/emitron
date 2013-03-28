#!perl

use strict;
use warnings;

use Test::More;

use Lintilla::Site;
use Dancer::Test;

route_exists [GET => '/asset/foo/var/high/123.jpg'];
#response_status_is ['GET' => '/'], 200;

done_testing();

# vim:ts=2:sw=2:et:ft=perl


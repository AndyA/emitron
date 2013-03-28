use Test::More tests => 2;
use strict;
use warnings;

# the order is important
use Lintilla::Site;
use Dancer::Test;

route_exists [GET => '/'];
response_status_is ['GET' => '/'], 200;

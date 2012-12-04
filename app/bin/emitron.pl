#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../../perl/Data-JSONPath/lib";

use Emitron::App root => '/tmp/emitron';
use Emitron::Logger;

Emitron::Logger->level( Emitron::Logger->DEBUG );

em->on(
  '$.streams.*.INR.*',
  sub {
    my ( $path, $before, $after, $name, $app ) = @_;
    info "$path ($name, $app): ", $before, $after;
  }
);

em->run;

# vim:ts=2:sw=2:sts=2:et:ft=perl

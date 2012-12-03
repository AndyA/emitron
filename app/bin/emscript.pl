#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../../perl/Data-JSONPath/lib";

use Emitron::Core root => '/tmp/emitron';

em->model->inject(
  {
    events => {
      roh => {
        name  => 'Royal Opera House',
        input => {
          roh1 => {},
          roh2 => {},
        },
      }
    }
  }
);

em->on(
  '$.streams.*.INR.*',
  sub {
    my ( $path, $before, $after, $name, $app ) = @_;
  }
);

em->run;

# vim:ts=2:sw=2:sts=2:et:ft=perl


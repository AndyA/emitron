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
  '+$.streams.*.INR.*',
  sub {
    my ( $path, undef, $after, $name, $app ) = @_;
    info "Created stream ($name, $app): ", $after;
    em->post_event(
      type => 'ev.something',
      msg  => { name => $name, app => $app }
    );
    em->on(
      "-$path",
      sub {
        my ( undef, $before, undef ) = @_;
        info "Destroyed stream ($name, $app): ", $before;
        em->off_all;
      }
    );
  }
);

em->on(
  'ev.something',
  sub {
    my $msg = shift;
    debug "Got event: ", $msg->type;
  }
);

em->run;

# vim:ts=2:sw=2:sts=2:et:ft=perl

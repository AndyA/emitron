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
  'msg.stream.encode.*' => sub {
    my ( $msg, $name ) = @_;
    debug "encode $name: ", $msg->type, ', ', $msg->msg;
  }
);

em->on(
  '+$.streams.*.INR.*' => sub {
    my ( $path, undef, $stream, $name, $app ) = @_;

    info "Created stream ($name, $app): ", $stream;

    em->on(
      "-$path" => sub {
        my ( undef, $before, undef ) = @_;
        info "Destroyed stream ($name, $app): ", $before;
        em->off_all;
      }
    );

    # Encode the preview stream
    em->post_message(
      type => "msg.stream.encode.$name",
      msg  => $stream
    );
  }
);

em->run;

# vim:ts=2:sw=2:sts=2:et:ft=perl

#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../../perl/Data-JSONPath/lib";

use Emitron::App root => '/tmp/emitron';
use Emitron::Tool::Encoder;
use Emitron::Logger;

Emitron::Logger->level( Emitron::Logger->DEBUG );

# TODO figure out a better way to clear handlers; having a single
# context per top-level activation isn't flexible enough.

em->on(
  'msg.stream.encode.*' => sub {
    my ( $msg, $name ) = @_;
    my $m = $msg->msg;
    debug "encode $name: ", $msg->type, ', ', $m;

    # Start stream encoding, update model
    my $enc = Emitron::Tool::Encoder->new(
      name   => $name,
      source => $m->{stream}{uri},
      config => $m->{config}
    );

    debug "Encoder message path is ", $enc->msg_path;
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
      msg  => {
        stream => $stream,
        config => '$.profiles.config.thumbnail'
      }
    );
  }
);

em->run;

# vim:ts=2:sw=2:sts=2:et:ft=perl

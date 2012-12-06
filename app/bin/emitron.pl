#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../../perl/Data-JSONPath/lib";

use Carp qw( verbose );
use Emitron::App root => '/tmp/emitron';
use Emitron::Logger;
use Emitron::Tool::Encoder;

Emitron::Logger->level( Emitron::Logger->DEBUG );

em->on(
  '+$.streams.*.INR.*' => sub {
    my ( $path, undef, $stream, $name, $app ) = @_;

    info "Created stream ($name, $app): ", $stream;

    em->on(
      "-$path" => sub {
        my ( undef, $before, undef ) = @_;
        info "Destroyed stream ($name, $app): ", $before;
        em->post_event(
          type => "evt.stream.encode.$name.thumbnail.stop",
          msg  => {}
        );
        em->post_event(
          type => "evt.stream.encode.$name.pc.stop",
          msg  => {}
        );
        em->off_all;
      }
    );

    # Encode the preview stream
    em->post_message(
      type => "msg.stream.encode.$name.thumbnail.start",
      msg  => {
        stream => $stream,
        config => '$.profiles.config.thumbnail'
      }
    );
    em->post_message(
      type => "msg.stream.encode.$name.pc.start",
      msg  => {
        stream => $stream,
        config => '$.profiles.config.pc'
      }
    );
  }
);

em->run;

# vim:ts=2:sw=2:sts=2:et:ft=perl

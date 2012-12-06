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

    my $enc_t = Emitron::Tool::Encoder->new(
      name   => "${name}_thumbnail",
      stream => $stream,
      config => '$.profiles.config.thumbnail'
    );

    my $enc_p = Emitron::Tool::Encoder->new(
      name   => "${name}_pc",
      stream => $stream,
      config => '$.profiles.config.pc'
    );

    em->on(
      "-$path" => sub {
        my ( undef, $before, undef ) = @_;
        info "Destroyed stream ($name, $app): ", $before;
        $enc_t->stop;
        $enc_p->stop;
        em->off_all;
      }
    );

    $enc_t->start;
    $enc_p->start;
  }
);

em->on(
  '+$.fragments.*' => sub {
    my ( $path, undef, $frag, $name ) = @_;

    info "Started encoding ($name)";

    em->on(
      "-$path" => sub {
        info "Stopped encoding ($name)";
        em->off_all;
      }
    );
  }
);

em->run;

# vim:ts=2:sw=2:sts=2:et:ft=perl

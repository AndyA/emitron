#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../../lib/perl/Data-JSONPath/lib";
use lib "$FindBin::Bin/../../lib/perl/Harmless/lib";
use lib "$FindBin::Bin/../../lib/perl/ForkPipe/lib";

use Carp qw( verbose );
use Emitron::App root => '/tmp/emitron';
use Emitron::Logger;
use Emitron::Tool::Deployer::S3;
use Emitron::Tool::Encoder;
use Emitron::Tool::Packager::HLS;

Emitron::Logger->level( Emitron::Logger->DEBUG );

em->on(
  '$.misc' => sub {
    my ( $p, $b, $a ) = @_;
    debug "misc: ", $b, " --> ", $a;
  }
);

em->on(
  '+$.streams.*.INR.*' => sub {
    my ( $path, undef, $stream, $name, $app ) = @_;

    info "Created stream ($name, $app): ", $stream;

    sleep 5;

    debug "Starting encoders for $name";

    my $enc_t = Emitron::Tool::Encoder->new(
      name   => "${name}_thumbnail",
      stream => $stream,
      config => '$.profiles.config.thumbnail',
      usage  => 'thumbnail',
    );

    my $enc_p = Emitron::Tool::Encoder->new(
      name   => "${name}_pc_hd_lite",
      stream => $stream,
      config => '$.profiles.config.pc_hd_lite',
      usage  => 'web',
      burnin => 1
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
  '+$.fragments.*.*' => sub {
    my ( $path, undef, $frag, $usage, $name ) = @_;

    info "Started packaging ($name)";

    my $pkgr = Emitron::Tool::Packager::HLS->new(
      name   => $name,
      stream => $frag,
      config => '$.packagers.default',
      usage  => $usage,
    );

    em->on(
      "-$path" => sub {
        info "Stopped packaging ($name)";
        $pkgr->stop;
        em->off_all;
      }
    );

    $pkgr->start;
  }
);

em->on(
  '+$.hls.thumbnail.*' => sub {
    my ( $path, undef, $hls, $name ) = @_;

    info "Started deploying ($name)";

    my $dep = Emitron::Tool::Deployer::S3->new(
      name   => $name,
      config => '$.deployers.s3.live',
      source => $hls,
      path   => 'x_emitron_test',
      pid    => 'x_emitron_test',
    );

    em->on(
      "-$path" => sub {
        info "Stopped deploying ($name)";
        $dep->stop;
        em->off_all;
      }
    );

    $dep->start;
  }
);

em->run;

# vim:ts=2:sw=2:sts=2:et:ft=perl

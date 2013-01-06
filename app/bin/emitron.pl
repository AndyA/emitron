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

use constant PID       => 'v0001gwq';
use constant PUBLISH   => 0;
use constant THUMBNAIL => 0;

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

    my @enc = ();

    if (THUMBNAIL) {
      push @enc,
       Emitron::Tool::Encoder->new(
        name   => "${name}_thumbnail",
        stream => $stream,
        config => '$.profiles.config.thumbnail',
        usage  => 'thumbnail',
       );
    }

    push @enc,
     Emitron::Tool::Encoder->new(
      name   => "${name}_pc_lite",
      stream => $stream,
      config => '$.profiles.config.pc_lite',
      usage  => 'web',
      burnin => 1
     );

    em->on(
      "-$path" => sub {
        my ( undef, $before, undef ) = @_;
        info "Destroyed stream ($name, $app): ", $before;
        $_->stop for @enc;
        em->off_all;
      }
    );

    $_->start for @enc;
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

if (PUBLISH) {
  em->on(
    '+$.hls.web.*' => sub {
      my ( $path, undef, $hls, $name ) = @_;

      info "Started deploying ($name)";

      my $dep = Emitron::Tool::Deployer::S3->new(
        name   => $name,
        config => '$.deployers.s3.live',
        source => $hls,
        path   => PID,
        pid    => PID,
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
}

em->run;

# vim:ts=2:sw=2:sts=2:et:ft=perl

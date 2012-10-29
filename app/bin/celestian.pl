#!/usr/bin/env perl

require 5.010;

use strict;
use warnings;

use Data::Dumper;
use POSIX qw( strftime );
use Term::ANSIColor;
use Time::HiRes qw( usleep  );

use lib qw( lib );

use Emitron::EvoStream;
use Emitron::Logger;
use Emitron::Model::App;
use Emitron::Model::EvoStream;

Emitron::Logger->level( Emitron::Logger->DEBUG );

my $app = Emitron::Model::App->new;
my $evo = Emitron::EvoStream->new;
my $es  = Emitron::Model::EvoStream->new( evo => $evo );
$es->on(
  added_stream => sub {
    my $obj = shift;
    info( "Hey - just added a streamable thing: ", $obj->name );
  }
);

$app->add( $es );

$app->run;

# vim:ts=2:sw=2:sts=2:et:ft=perl


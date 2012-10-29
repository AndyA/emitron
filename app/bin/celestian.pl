#!/usr/bin/env perl

require 5.010;

use strict;
use warnings;

use Data::Dumper;
use POSIX qw( strftime );
use Term::ANSIColor;
use Time::HiRes qw( usleep  );

use lib qw( lib );

use Celestian::EvoStream;
use Celestian::Logger;
use Celestian::Model::App;
use Celestian::Model::EvoStream;

Celestian::Logger->level( Celestian::Logger->DEBUG );

my $app = Celestian::Model::App->new;
my $evo = Celestian::EvoStream->new;
my $es  = Celestian::Model::EvoStream->new( evo => $evo );
$es->on(
  added_stream => sub {
    my $obj = shift;
    info( "Hey - just added a streamable thing: ", $obj->name );
  }
);

$app->add( $es );

$app->run;

# vim:ts=2:sw=2:sts=2:et:ft=perl


#!/usr/bin/env perl

require 5.010;

use strict;
use warnings;

use Data::Dumper;
use POSIX qw( strftime );
use Term::ANSIColor;
use Time::HiRes qw( usleep  );

use lib qw( lib );

use NewStream::EvoStream;
use NewStream::Logger;
use NewStream::Model::App;
use NewStream::Model::EvoStream;

NewStream::Logger->level( NewStream::Logger->DEBUG );

my $app = NewStream::Model::App->new;
my $evo = NewStream::EvoStream->new;
my $es  = NewStream::Model::EvoStream->new( evo => $evo );
$es->on(
  added_stream => sub {
    my $obj = shift;
    info( "Hey - just added a streamable thing: ", $obj->name );
  }
);

$app->add( $es );

$app->run;

# vim:ts=2:sw=2:sts=2:et:ft=perl


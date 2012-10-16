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
my $evo
 = NewStream::Model::EvoStream->new( evo => NewStream::EvoStream->new );
$app->add( $evo );
$app->run;

# vim:ts=2:sw=2:sts=2:et:ft=perl


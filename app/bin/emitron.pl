#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Emitron::App;
use Emitron::Logger;

Emitron::Logger->level( Emitron::Logger->DEBUG );

Emitron::App->new->run;

# vim:ts=2:sw=2:sts=2:et:ft=perl

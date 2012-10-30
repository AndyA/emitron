#!/usr/bin/env perl

use strict;
use warnings;

use IPC::GlobalEvent qw( eventsignal eventwait );

use constant SEMFILE => '/tmp/emitron.event';

my $sn = shift || 0;

eventsignal( SEMFILE, $sn );

# vim:ts=2:sw=2:sts=2:et:ft=perl


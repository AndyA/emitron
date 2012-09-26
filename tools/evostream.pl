#!/usr/bin/env perl

use strict;
use warnings;

use lib qw( app/lib );

use NewStream::EvoStream;

use Data::Dumper;

my $evo = NewStream::EvoStream->new( host => 'localhost' );
print Dumper( $evo->version );

# vim:ts=2:sw=2:sts=2:et:ft=perl


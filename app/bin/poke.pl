#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Emitron::Model::Watched;

use constant MODEL => '/tmp/emitron.model';

our $VERSION = '0.1';

my $model = Emitron::Model::Watched->new( root => MODEL );
$model->init;

$model->commit( { args => \@ARGV } );

# vim:ts=2:sw=2:sts=2:et:ft=perl


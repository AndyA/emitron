#!/usr/bin/env perl

use strict;
use warnings;

use JSON;
use Path::Class;

use constant STASH => dir '../lintilla/spider/stash';
use constant DB    => file STASH, 'db.json';
use constant OUT   => dir 'webroot/ace/data';

my $db = JSON->new->utf8->decode( scalar file(DB)->slurp );

for my $rec (@$db) {
  my $id = $rec->{'Film ID'};
  OUT->mkpath;
  my $out = file OUT, "$id.json";
  my $fh = $out->openw;
  $fh->binmode(':utf8');
  print $fh JSON->new->encode($rec);
}

# vim:ts=2:sw=2:sts=2:et:ft=perl


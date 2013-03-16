#!perl

use strict;
use warnings;
use Test::More;

use RDF::FourStore::Namespace;

my $ns = RDF::FourStore::Namespace->new;

my @sparql = split /\n/, $ns->to_sparql;
ok @sparql > 5, 'got some lines';
for my $ln (@sparql) {
  like $ln, qr{^PREFIX\s+\w+\s*:\s*<http://\S+?>$}, "declaration";
}

done_testing();

# vim:ts=2:sw=2:et:ft=perl


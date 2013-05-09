#!perl

use strict;
use warnings;

use Data::Dumper;
use Test::More;

use RDF::FourStore;

ok my $fs
 = RDF::FourStore->new( endpoint => 'http://localhost:9000' ),
 'new';
isa_ok $fs, 'RDF::FourStore';

#my $rs = $fs->select('SELECT * WHERE { ?s ?p ?o }');
#diag Dumper($rs);

done_testing();

# vim:ts=2:sw=2:et:ft=perl


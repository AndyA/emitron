use strict;
use warnings;

use lib 'inc', 't/lib';

use Module::Build;
use MyBuilder;

my $builder = MyBuilder->new(
  module_name       => 'RDF::FourStore',
  license           => 'perl',
  dist_author       => 'Andy Armstrong <andy@hexten.net>',
  dist_version_from => 'lib/RDF/FourStore.pm',
  requires          => { 'Test::More' => 0, },
  add_to_cleanup    => ['RDF-FourStore-*'],
);

$builder->create_build_script();

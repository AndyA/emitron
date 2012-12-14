use strict;
use warnings;

use lib 'inc', 't/lib';

use Module::Build;
use MyBuilder;

my $builder = MyBuilder->new(
  module_name       => 'Data::JSONPath',
  license           => 'perl',
  dist_author       => 'Andy Armstrong <andy@hexten.net>',
  dist_version_from => 'lib/Data/JSONPath.pm',
  requires          => { 'Test::More' => 0, },
  add_to_cleanup    => ['Data-JSONPath-*'],
);

$builder->create_build_script();

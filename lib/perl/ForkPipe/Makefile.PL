use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'ForkPipe',
  AUTHOR       => q{Andy Armstrong <andy@hexten.net>},
  VERSION_FROM => 'lib/ForkPipe.pm',
  ABSTRACT     => '',
  ( $ExtUtils::MakeMaker::VERSION >= 6.3002
    ? ( 'LICENSE' => 'perl' )
    : () ),
  PL_FILES  => {},
  PREREQ_PM => {
    'accessors::ro'       => 0,
    'Carp'                => 0,
    'Data::Dumper'        => 0,
    'DateTime'            => 0,
    'ExtUtils::MakeMaker' => 0,
    'File::Temp'          => 0,
    'FindBin'             => 0,
    'Path::Class'         => 0,
    'Storable'            => 0,
    'Test::Differences'   => 0,
    'Test::More'          => 0,
  },
  dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  clean => { FILES    => 'ForkPipe-*' },
);

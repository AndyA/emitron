use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Harmless',
  AUTHOR       => q{Andy Armstrong <andy@hexten.net>},
  VERSION_FROM => 'lib/Harmless.pm',
  ABSTRACT     => '',
  ( $ExtUtils::MakeMaker::VERSION >= 6.3002
    ? ( 'LICENSE' => 'perl' )
    : () ),
  PL_FILES  => {},
  PREREQ_PM => {},
  dist      => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  clean => { FILES => 'Harmless-*' },
);

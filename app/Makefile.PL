use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Emitron',
  AUTHOR       => q{Andy Armstrong <andy@hexten.net>},
  VERSION_FROM => 'lib/Emitron.pm',
  ABSTRACT     => 'Live streaming for everyone',
  ( $ExtUtils::MakeMaker::VERSION >= 6.3002
    ? ( 'LICENSE' => 'perl' )
    : () ),
  PL_FILES  => {},
  PREREQ_PM => {
    'Carp'                      => 0,
    'Config::Tiny'              => 0,
    'Dancer'                    => '1.31',
    'Dancer::Test'              => 0,
    'Data::Dumper'              => 0,
    'Data::JSONPath'            => 0,
    'ExtUtils::MakeMaker'       => 0,
    'File::Basename'            => 0,
    'File::Find'                => 0,
    'File::Path'                => 0,
    'File::Spec'                => 0,
    'File::Temp'                => 0,
    'FindBin'                   => 0,
    'Getopt::Long'              => 0,
    'Harmless'                  => 0,
    'IO::Handle'                => 0,
    'IO::Select'                => 0,
    'JSON'                      => 0,
    'JSON::XS'                  => 0,
    'LWP::UserAgent'            => 0,
    'Linux::Inotify2'           => '1.22',
    'List::Util'                => 0,
    'MIME::Base64'              => 0,
    'POSIX'                     => 0,
    'Path::Class'               => 0,
    'Plack::Handler::FCGI'      => 0,
    'Plack::Runner'             => 0,
    'Scalar::Util'              => 0,
    'Storable'                  => 0,
    'String::ShellQuote'        => '1.03',
    'Sys::Hostname'             => 0,
    'Term::ANSIColor'           => 0,
    'Test::More'                => 0,
    'Time::HiRes'               => 0,
    'URI::Escape'               => 0,
    'XML::LibXML'               => 0,
    'XML::LibXML::XPathContext' => 0,
    'YAML'                      => 0,
  },
  dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  clean => { FILES    => 'Emitron-*' },
);

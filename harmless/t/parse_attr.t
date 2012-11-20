#!perl

use strict;
use warnings;
use Test::More;

use Harmless::M3U8::Parser;

my @case = (
  {
    source => 'PROGRAM-ID=1',
    want   => [ 'PROGRAM-ID', 1 ]
  },
  {
    source =>
     'PROGRAM-ID=1,BANDWIDTH=232370,CODECS="mp4a.40.2, avc1.4d4015"',
    want => [
      'PROGRAM-ID', 1,
      BANDWIDTH => 232370,
      CODECS    => "mp4a.40.2, avc1.4d4015",
    ]
  },
);

plan tests => 1 * @case;

for my $tc ( @case ) {
  my $name = $tc->{source};
  my @got  = Harmless::M3U8::Parser::_parse_attr( $tc->{source} );
  is_deeply \@got, $tc->{want}, "$name: parsed OK";
}

# vim:ts=2:sw=2:et:ft=perl


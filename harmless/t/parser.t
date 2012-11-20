#!perl

use strict;
use warnings;

use Data::Dumper;
use File::Spec;
use Test::More;

use Harmless::M3U8::Parser;

use constant REF => 't/ref';

my @case = (
  {
    source => 'bipbop_4x3_variant/bipbop_4x3_variant.m3u8',
    want   => [ { stream_inf => { CODECS       => "mp4a.40.2, avc1.4d4015", "PROGRAM-ID" => 1, BANDWIDTH    => 232370 }, uri => "gear1/prog_index.m3u8" }, { stream_inf => { CODECS       => "mp4a.40.2, avc1.4d401e", "PROGRAM-ID" => 1, BANDWIDTH    => 649879 }, uri => "gear2/prog_index.m3u8" }, { stream_inf => { CODECS       => "mp4a.40.2, avc1.4d401e", "PROGRAM-ID" => 1, BANDWIDTH    => 991714 }, uri => "gear3/prog_index.m3u8" }, { stream_inf => { CODECS       => "mp4a.40.2, avc1.4d401f", "PROGRAM-ID" => 1, BANDWIDTH    => 1927833 }, uri => "gear4/prog_index.m3u8" }, { stream_inf => { CODECS       => "mp4a.40.2", "PROGRAM-ID" => 1, BANDWIDTH    => 41457 }, uri => "gear0/prog_index.m3u8" } ], });

plan tests => 4 * @case;

for my $tc ( @case ) {
  my $name = $tc->{source};
  ok my $p = Harmless::M3U8::Parser->new, "$name: new";
  isa_ok $p, 'Harmless::M3U8::Parser';
  my $src = File::Spec->catfile( REF, $tc->{source} );
  my $got = eval { $p->parse_file( $src ) };
  my $err = $@;
  if ( $tc->{want} ) {
    ok !$err, "$name: no error";
    is_deeply $got, $tc->{want}, "$name: parsed"
     or diag dd( [ $got, $tc->{want} ], [ 'got', 'want' ] );
  }
  else {
    ok $err, "$name: error reported";
    like $err, $tc->{want_error}, "$name: error matches";
  }
}

sub dd {
  Data::Dumper->new( @_ )->Indent( 2 )->Quotekeys( 0 )->Useqq( 1 )
   ->Dump;
}

# vim:ts=2:sw=2:et:ft=perl


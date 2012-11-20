#!perl

use strict;
use warnings;

use Path::Class;
use File::Temp;
use Test::More;
use Test::Differences;
use Storable qw( dclone );

use Harmless::M3U8::Formatter;
use Harmless::M3U8::Parser;

use constant REF => 't/data';

my @case = (
  { source => 'simple_root.m3u8', },
  { source => 'simple_var.m3u8', },
  { source => 'discontinuity.m3u8', },
  { source => 'byterange.m3u8', },
  { source => 'datetime.m3u8', },
  { source => 'endlist.m3u8', },
  { source => 'complex.m3u8', },
);

plan tests => 2 * @case;

for my $tc ( @case ) {
  my $name = $tc->{source};
  my $src  = file( REF, $tc->{source} );
  my $orig = Harmless::M3U8::Parser->new->parse_file( $src );
  my $tmp  = dclone $orig;
  my $tf   = File::Temp->new;
  my $m3u8 = Harmless::M3U8::Formatter->new->format( $tmp );
  eq_or_diff $tmp, $orig, "$name: unmodified";
  print { file( $tf->filename )->openw } $m3u8;
  my $new = Harmless::M3U8::Parser->new->parse_file( $tf->filename );
  eq_or_diff $new, $orig, "$name: round trip";
}

# vim:ts=2:sw=2:et:ft=perl


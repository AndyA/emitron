#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long;
use Path::Class;

my %O = (
  even   => 0,
  number => '10%',
);

GetOptions(
  'E|even'    => \$O{even},
  'n|count:s' => \$O{number},
) or die syntax();

my @lines = map file($_)->slurp, @ARGV;

my $count
 = $O{number} =~ /^(\d+(?:\.\d+)?)%$/ ? int( 0.5 + $1 * @lines / 100 )
 : $O{number} =~ /^(\d+(?:\.\d+)?)$/  ? $1
 :                                      die "Bad count\n";

if ( $O{even} ) {
  print $lines[$_ * @lines / $count] for 0 .. $count - 1;
}
else {
  print splice @lines, int( rand @lines ), 1 while $count-- > 0 && @lines;
}

sub syntax {
  <<EOT;
Usage: $0 [options] <file>...

Options:
  -E, --even      Choose evenly spaced elements (otherwise random)
  -n <num>|<pc>%  Number of samples

EOT
}

# vim:ts=2:sw=2:sts=2:et:ft=perl


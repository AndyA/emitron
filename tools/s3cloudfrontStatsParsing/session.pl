#!/usr/bin/perl
#
# Quick and dirty session detect. Ensure that for each time slot,
# default a minute, we have roughly the right number of TS files
# fetched. We do not really bother with ordering (yet) - i.e. a
# user that does FWD/BWD winding is fine too.
#
# 
#   Copyright 2012 BBC
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

use strict;                     
use warnings; 
use HTTP::Date;

my $ifall = 600; # seconds
my $globs = 4; # seconds
my $slack = 0.85; # percentage ish something

push @ARGV,'-' if $#ARGV == -1;

my %seen = ();
my %full = ();

for my $file (@ARGV) {
open(STDIN, $file)
	or die "Could not open <$file>: $!\n"
	unless $file eq '-';

$|++;
my %tally=(); # Python does not have sparse arrays.

while(<STDIN>) {
	# http://docs.amazonwebservices.com/AmazonCloudFront/latest/DeveloperGuide/AccessLogs.html
	#
	my ($date,$time,$edge,$bytes,$ip,$method,$host,$path,$status,$ref,$ua,
		$qstring,$cookie,$result,$id)=split;

	print "$date-$time RESET\n", next
		if $path =~ m/\.js/ || $path =~ m/\.swf/;

	next unless $path =~ m/(\d+)\.ts/;
	my $idx = $1;

	# push @lst, "$date-$time $path";

	my $dt = int(str2time("$date $time")/$ifall)
		or die "Failed to parse $date $time.\n";

	$tally{$dt} = [] unless defined $tally{$dt};

	push @{ $tally{$dt} }, $idx;
}

	open FH,">$file.$ifall"
		or die "Could not open $file.$ifall: $!\n";
foreach(sort keys %tally) {
	my $dt = $ifall * $_;
	my $d = time2str($dt);
	my $b = $#{$tally{$_}};
	my $a = '0';
	$a = '1' if $b * $globs > $ifall * $slack;

	print FH "$dt	$a	$b	$d\n";

	$seen{ $dt } ++;
	$full{ $dt } ++ if $a == 1;
};
};

print "#plotDate, #seen, #full, #str\n";
foreach(sort keys %seen) {
	my $d = time2str($_);	# add human readable one to make live easier.
	my $b = 0;
	$b = $full{$_} if defined $full{$_};

	my $plot_date = $_ - 978307200.0;
	print "$plot_date,$seen{$_},$b\n";
};

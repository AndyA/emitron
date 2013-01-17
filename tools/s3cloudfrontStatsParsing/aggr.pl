#!/usr/bin/perl
#
# Aggregate session blocks across IP/UA strings
# into overall concurrent counts.
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
use HTTP::Date;

my $file = shift @ARGV || '10-mins.txt';

open(STDIN, $file)
	or die "Could not open <$file>: $!\n"
	unless $file eq '-';

$|++;
my %full=(); 
my %seen =(); 

while(<STDIN>) {
	# 12262621 0       21      Mon, 07 Jan 2013 15:30:00 GMT
	#
	my ($dt, $s, $f) = split m/[\t,]/;

	$seen{$dt} += $s;
	$full{$dt} += $f;
}

print "#plotDate, #seen, #full, #str\n";
foreach(sort keys %seen) {
	my $d = time2str($_);	# add human readable one to make live easier.
	my $b = 0 + $full{$_};
	my $plot_date = $_; # - 978307200.0;
	print "$plot_date,$seen{$_},$b,	$d\n";
};

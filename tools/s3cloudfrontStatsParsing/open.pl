#!/usr/bin/perl
#
# Extract the PIDs from a master reference; extract hits for these
# from the cloud log files and output. No sorting is done as
# cloudfront log files are out of order.
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
use LWP::Simple;                # From CPAN
use JSON qw( decode_json );     # From CPAN
use Data::Dumper;               # Perl core module
use strict;                     # Good practice
use warnings; 

my $dir = shift @ARGV || 'open';
my $pid = shift @ARGV || "e0001grq";

$pid = "http://thespace.org/items/$pid" unless $pid =~m/^http/;
$pid .= '.json' unless $pid =~ m/\.json$/;

my $json = get( $pid) 
	or die "Could not get <$pid>.\n";

my $decoded_json = decode_json( $json );

# print Dumper $decoded_json;

die "Hmm - no versions or stuff like that\n"
	unless my @versions = @{$decoded_json->{programme}->{versions}};

my %pids = ();
map { $pids{  $_->{pid} } = 1; } @versions;

print "Scanning for ".join(' ',keys %pids)."\n";


die "<$dir> not a directory."
	unless -d $dir || $dir eq '-';

my($ign, $err, $cap, $hit, $lines, $pe) = (0,0,0,0,0,0);

# We do not really get much native ordering in the
# magic IDs - and some blocks seem to be delayed
# so we'll leave sorting to (much) later.
#
open(STDIN, "zcat $dir/*gz |") 
	unless $dir eq '-';

$|++;
while(<STDIN>) {
	# http://docs.amazonwebservices.com/AmazonCloudFront/latest/DeveloperGuide/AccessLogs.html
	my ($date,$time,$edge,$bytes,$ip,$method,$host,$path,$status,$ref,$ua,
		$qstring,$cookie,$result,$id)=split;

	next if m/^#/;

	if (($id !~ m/\w+/ and  $result ne 'Error') or $path !~ m|^/(\w+)|) {
		warn "$err: $_ at line $.\n";
		$pe++;
		next;
	};

	my $pid = $1;

	$lines++;

	$ign++, next 
		unless $pids{$pid};

	$err++, next
		if $result eq 'Error';

	$cap++, next
		if $result eq 'CapacityExceeded';
	$hit++;

	print;
}

warn "Results

Ignored:	$ign
Errors:		$err
Capacity:	$cap
In scope:	$hit
Parsefails:	$pe
Lines		$lines
";

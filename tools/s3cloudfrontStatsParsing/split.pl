#!/usr/bin/perl
#
# Break up the log into small per IP, per UA files for easier
# sorting and handling later.
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

use Digest::SHA1  qw(sha1 sha1_hex sha1_base64);
use File::Path;

my $file = shift @ARGV || 'just-roh.log';

open(STDIN, $file)
	unless $file eq '-';

$|++;
while(<STDIN>) {
	# http://docs.amazonwebservices.com/AmazonCloudFront/latest/DeveloperGuide/AccessLogs.html
	my ($date,$time,$edge,$bytes,$ip,$method,$host,$path,$status,$ref,$ua,
		$qstring,$cookie,$result,$id)=split;

	my $hash = sha1_hex($ip . $ua);
	my $prefix = substr($hash,0,4);
	substr($prefix,4,0)='/';
	substr($prefix,2,0)='/';
	substr($prefix,0,0)='out/';

	mkpath($prefix);
	open(STDOUT,">>$prefix/$hash") or die;
	print STDOUT;
}

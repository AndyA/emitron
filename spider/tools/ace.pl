#!/usr/bin/env perl

use strict;
use warnings;

use Encode;
use JSON;
use LWP::UserAgent;
use Path::Class;
use pQuery;

use constant URL =>
 "http://artsonfilm.wmin.ac.uk/films.php?a=view&recid=%d";

use constant OUT => 'stash';

my $pn = 0;
PAGE: {
  my $body = get_page($pn);
  my $rec  = parse_page($body);

  {
    my $out = file OUT, sprintf 'r%08d.json', $pn;
    print "Writing $out\n";
    $out->parent->mkpath;
    my $fh = $out->openw;
    $fh->binmode(':utf8');
    print $fh JSON->new->pretty->encode($rec);
  }

  if ( $body =~ m{films\.php.*recid=(\d+)">Next\s+Record} ) {
    $pn = $1;
    redo PAGE;
  }
}

sub parse_page {
  my $body = shift;
  my $pq   = pQuery($body);
  my $rec  = {};
  $pq->find('.tbl')->each(
    sub {
      pQuery($_)->find('tr')->each(
        sub {
          my $nd = $_;
          my %kv = ();
          pQuery($_)->find('td')->each(
            sub {
              $kv{ $_->getAttribute("class") } = pQuery($_)->text;
            }
          );
          if ( exists $kv{hr} && exists $kv{dr} ) {
            $rec->{ $kv{hr} } = $kv{dr};
          }
          else {
            warn "Missing hr/dr";
          }
        }
      );
    }
  );
  return $rec;
}

sub get_page {
  my $pn   = shift;
  my $ua   = LWP::UserAgent->new;
  my $resp = $ua->get( sprintf URL, $pn );
  die $resp->status_line if $resp->is_error;
  return decode( "cp1252", $resp->content );
}

# vim:ts=2:sw=2:sts=2:et:ft=perl


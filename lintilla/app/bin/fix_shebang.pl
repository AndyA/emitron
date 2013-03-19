#!/usr/bin/env perl

use strict;
use warnings;

use File::Which qw( which );
use Path::Class;

my %FIX = ( perl => ['public/dispatch.cgi', 'public/dispatch.fcgi'] );

while ( my ( $lang, $scripts ) = each %FIX ) {
  my $interp = which $lang;
  die "Can't find an interpreter for $lang" unless defined $interp;
  print "$lang is $interp\n";
  for my $script (@$scripts) {
    print "  fixing $script\n";
    set_shebang( $script, $interp );
  }
}

sub set_shebang {
  my ( $script, $interp ) = @_;
  my @li = file($script)->slurp;
  $li[0] = "#!$interp\n";
  my $tmp = file("$script.tmp");
  { print { $tmp->openw } join '', @li }
  chmod( ( stat $script )[2], $tmp );
  rename "$tmp", $script or die "Can't rename $tmp as $script";
}

# vim:ts=2:sw=2:sts=2:et:ft=perl


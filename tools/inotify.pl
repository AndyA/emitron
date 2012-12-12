#!/usr/bin/env perl

use strict;
use warnings;

use Linux::Inotify2;

{
  my @f = qw(
   IN_ACCESS
   IN_MODIFY
   IN_ATTRIB
   IN_CLOSE_WRITE
   IN_CLOSE_NOWRITE
   IN_OPEN
   IN_MOVED_FROM
   IN_MOVED_TO
   IN_CREATE
   IN_DELETE
   IN_DELETE_SELF
   IN_MOVE_SELF
  );

  my %map = ();

  for my $f ( @f ) {
    no strict 'refs';
    my $v = &{$f}();
    $map{$v} = $f;
  }

  sub indec {
    my $fl = shift;
    join '+', sort map { $map{$_} } grep { $fl & $_ } keys %map;
  }
}

# vim:ts=2:sw=2:sts=2:et:ft=perl


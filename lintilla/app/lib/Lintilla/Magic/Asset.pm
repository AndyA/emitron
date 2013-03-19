package Lintilla::Magic::Asset;

use Moose;

=head1 NAME

Lintilla::Magic::Asset - A dynamic, cached asset

=cut

has basename => ( isa => 'Str', is => 'ro' );

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

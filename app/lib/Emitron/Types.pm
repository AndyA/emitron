package Emitron::Types;

use Moose;
use Moose::Util::TypeConstraints;

=head1 NAME

Emitron::Types - Moose typedefs

=cut

subtype 'Name', as 'Str', where { $_ =~ /^\w[\d\w]*$/ }, message {
  'Names must have identifier semantics (letters and digits, leading letter)';
};

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

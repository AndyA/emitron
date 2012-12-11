package Emitron::Tool::Base;

use Moose;

use Emitron::Types;

=head1 NAME

Emitron::Tool::Base - An asynchronous tool

=cut

has name => ( isa => 'Name', is => 'ro', required => 1 );

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

package Emitron::Tool::Encoder;

use Moose;

extends 'Emitron::Tool::Base';

=head1 NAME

Emitron::Tool::Encoder - A multi bit rate encoder

=cut

has source => ( isa => 'Str', is => 'ro', required => 1 );

sub prefix { 'stream.encode' }

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

package Emitron::Media::Packager::HLS;

use Moose;

use Emitron::Media::Globals;
use Emitron::Media::Programs;
use Harmless::M3U8;
use Harmless::Segment;

extends 'Emitron::Media::Base';

has webroot => ( isa => 'Str', is => 'ro', required => 1 );
has config => ( isa => 'ArrayRef[HashRef]', is => 'ro', required => 1 );

=head1 NAME

Emitron::Media::Packager::HLS - HLS packager

=cut

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

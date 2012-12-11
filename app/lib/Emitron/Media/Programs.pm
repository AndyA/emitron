package Emitron::Media::Programs;

use Moose;

=head1 NAME

Emitron::Media::Programs - Program locations

=cut

has bash       => ( isa => 'Str', is => 'ro', default => '/bin/bash' );
has ffmpeg     => ( isa => 'Str', is => 'ro', default => 'ffmpeg' );
has gst_launch => ( isa => 'Str', is => 'ro', default => 'gst-launch' );
has tsdemux    => ( isa => 'Str', is => 'ro', default => 'tsdemux' );

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

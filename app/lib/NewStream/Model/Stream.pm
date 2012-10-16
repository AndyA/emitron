package NewStream::Model::Stream;

use strict;
use warnings;

use NewStream::Logger;

use base qw( NewStream::Model::Base );

use constant kind => 'stream';

use accessors::ro qw( evo id );

=head1 NAME

NewStream::Model::Stream - A stream

=cut

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

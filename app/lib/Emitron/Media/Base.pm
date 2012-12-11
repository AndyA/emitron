package Emitron::Media::Base;

use Moose;

use Emitron::Types;

=head1 NAME

Emitron::Media::Base - Media handlers base class

=cut

has name => ( isa => 'Name', is => 'ro', required => 1 );

has programs => (
  isa     => 'Emitron::Media::Programs',
  is      => 'ro',
  default => sub { Emitron::Media::Programs->new }
);

has globals => (
  isa     => 'Emitron::Media::Globals',
  is      => 'ro',
  default => sub { Emitron::Media::Globals->new }
);

has _tmp_dir => (
  isa     => 'File::Temp::Dir',
  is      => 'ro',
  lazy    => 1,
  default => sub { File::Temp->newdir( TEMPLATE => 'emXXXXX' ) }
);

has tmp_dir => (
  isa     => 'Str',
  is      => 'ro',
  lazy    => 1,
  default => sub { shift->_tmp_dir->dirname }
);

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

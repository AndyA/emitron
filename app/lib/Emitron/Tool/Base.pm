package Emitron::Tool::Base;

use Moose;

=head1 NAME

Emitron::Tool::Base - An asynchronous tool

=cut

has name => ( isa => 'Str', is => 'ro', required => 1 );
has msg_path => (
  isa     => 'Str',
  is      => 'ro',
  lazy    => 1,
  default => sub {
    my $self = shift;
    join '.', $self->prefix, $self->name;
  }
);

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

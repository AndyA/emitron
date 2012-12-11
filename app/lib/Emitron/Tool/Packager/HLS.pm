package Emitron::Tool::Packager::HLS;

use Moose;

use Emitron::App;
use Emitron::Logger;
use Emitron::Media::Packager::HLS;

extends 'Emitron::Tool::Base';

=head1 NAME

Emitron::Tool::Packager::HLS - HLS Packager

=cut

has packager => (
  isa     => 'Emitron::Media::Packager::HLS',
  is      => 'ro',
  lazy    => 1,
  builder => '_mk_packager',
  handles => [ 'start', 'stop' ]
);

has config => ( isa => 'Str', is => 'ro', required => 1 );

sub _mk_packager {
  my $self = shift;
  my %arg  = (
    name    => $self->name,
    config  => [],
    webroot => 'webroot/live/hls/foo',
  );
  return Emitron::Media::Packager::HLS->new( %arg );
}

before start => sub {
  my $self = shift;
  debug "Start HLS packager ", $self->name, " with config ",
   $self->config;
};

before stop => sub {
  my $self = shift;
  debug "Stop HLS packager ", $self->name, " with config ",
   $self->config;
};

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

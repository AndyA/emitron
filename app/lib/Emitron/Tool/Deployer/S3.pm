package Emitron::Tool::Deployer::S3;

use Moose;

use Emitron::App;
use Emitron::Logger;
use Emitron::Media::Deployer::S3;

extends 'Emitron::Tool::Base';

has deployer => (
  isa     => 'Emitron::Media::Deployer::S3',
  is      => 'ro',
  lazy    => 1,
  builder => '_mk_deployer',
  handles => ['start', 'stop']
);

=head1 NAME

Emitron::Tool::Deployer::S3 - S3 Deployer

=cut

has ['config', 'path', 'pid'] => (
  isa      => 'Str',
  is       => 'ro',
  required => 1,
);

has source => ( isa => 'HashRef', is => 'ro', required => 1 );

sub _mk_deployer {
  my $self = shift;
  my $cfg  = em->cfg( $self->config );
  return Emitron::Media::Deployer::S3->new(
    name       => $self->name,
    path       => $self->path,
    pid        => $self->pid,
    manifest   => $self->source->{manifest},
    config     => $cfg,
    make_index => 1,
  );
}

before start => sub {
  my $self = shift;
  debug "Start S3 deployer ", $self->name, " with config ", $self->config,
   " for source ", $self->source;
};

before stop => sub {
  my $self = shift;
  debug "Stop S3 deployer ", $self->name, " with config ", $self->config;
};

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

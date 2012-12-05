package Emitron::Context;

use Moose;

use Emitron::Config;
use Emitron::MessageDespatcher;
use Emitron::Model::Watched;

use constant QUEUE => '/tmp/emitron.queue';
use constant MODEL => '/tmp/emitron.model';
use constant EVENT => '/tmp/emitron.event';

has model => (
  isa     => 'Emitron::Model::Watched',
  is      => 'ro',
  lazy    => 1,
  default => sub {
    Emitron::Model::Watched->new( root => MODEL, prune => 50 )
     ->init( Emitron::Config->config );
  }
);

has queue => (
  isa     => 'Emitron::Model::Watched',
  is      => 'ro',
  lazy    => 1,
  default => sub {
    Emitron::Model::Watched->new( root => QUEUE )->init;
  }
);

has event => (
  isa     => 'Emitron::Model::Watched',
  is      => 'ro',
  lazy    => 1,
  default => sub {
    Emitron::Model::Watched->new( root => EVENT, prune => 50 )->init;
  }
);

has despatcher => (
  isa     => 'Emitron::MessageDespatcher',
  is      => 'ro',
  lazy    => 1,
  default => sub { Emitron::MessageDespatcher->new }
);

=head1 NAME

Emitron::Context - Runtime context

=cut

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

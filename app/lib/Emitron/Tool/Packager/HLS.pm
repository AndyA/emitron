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
  handles => ['start', 'stop', 'manifest']
);

has stream => ( isa => 'HashRef', is => 'ro', required => 1 );
has config => ( isa => 'Str',     is => 'ro', required => 1 );

sub _mk_packager {
  my $self = shift;

  my $stm = $self->stream;
  my @cnf = ();
  my @pro = (
    sort { $stm->{$a}{order} <=> $stm->{$b}{order} }
     keys %$stm
  );

  for my $pro (@pro) {
    push @cnf, { name => $pro, %{ $stm->{$pro} } };
  }

  my $cfg = em->cfg( $self->config );

  my %arg = (
    name    => $self->name,
    config  => \@cnf,
    webroot => $cfg->{webroot}
  );

  return Emitron::Media::Packager::HLS->new(%arg);
}

before start => sub {
  my $self = shift;
  debug "Start HLS packager ", $self->name, " with config ", $self->config;
};

after start => sub {
  my $self = shift;
  em->model->transaction(
    sub {
      my ( $m, $rev ) = @_;
      $m->{hls}{ $self->name } = { manifest => $self->manifest };
      return $m;
    }
  );
};

before stop => sub {
  my $self = shift;
  debug "Stop HLS packager ", $self->name, " with config ", $self->config;
  em->model->transaction(
    sub {
      my ( $m, $rev ) = @_;
      delete $m->{hls}{ $self->name };
      return $m;
    }
  );
};

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

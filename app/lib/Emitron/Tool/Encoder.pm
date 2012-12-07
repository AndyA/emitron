package Emitron::Tool::Encoder;

use Moose;

extends 'Emitron::Tool::Base';

use Emitron::App;
use Emitron::Logger;
use Emitron::Media::Encoder;
use Path::Class;

has encoder => (
  isa     => 'Emitron::Media::Encoder',
  is      => 'ro',
  lazy    => 1,
  builder => '_mk_encoder',
  handles => [ 'start', 'stop' ]
);

has stream => ( isa => 'HashRef', is => 'ro', required => 1 );
has config => ( isa => 'Str',     is => 'ro', required => 1 );
has burnin => ( isa => 'Bool',    is => 'ro', default  => 0 );

has _model => ( isa => 'HashRef', is => 'rw' );

=head1 NAME

Emitron::Tool::Encoder - A multi bit rate encoder

=cut

sub _mk_encoder {
  my $self = shift;
  my %seen = ();
  my @conf = ();
  my $dog;
  my $dir   = em->work_dir( $self->name );
  my $model = {};
  my $stm   = $self->stream;
  my $seg   = '%08d.ts';
  em->cfg(
    $self->config,
    sub {
      my $cfg = shift;
      for my $enc ( @{ $cfg->{encodes} } ) {
        next if $seen{$enc}++;
        my $odir = dir( $dir, $enc );
        $odir->mkpath;
        my $pro = em->cfg( "\$.profiles.encodes.$enc" );
        unless ( defined $pro ) {
          error "Can't find profile: $enc";
          next;
        }
        $model->{$enc} = {
          dir     => "$odir",
          segment => $seg,
          profile => $pro
        };
        push @conf,
         {
          name        => $enc,
          destination => "$odir/%08d.ts",
          profile     => $pro
         };
      }
      $dog ||= $cfg->{dog};
    }
  );
  my %arg = (
    name    => $self->name,
    source  => $stm->{rtsp},
    config  => \@conf,
    tmp_dir => $dir,
    burnin  => $self->burnin,
  );
  $arg{dog} = $dog if defined $dog;

  $self->_model( $model );

  return Emitron::Media::Encoder->new( %arg );
}

before start => sub {
  my $self = shift;
  debug "Start encode ", $self->name, " with config ", $self->config;
};

after start => sub {
  my $self = shift;
  em->model->transaction(
    sub {
      my ( $m, $rev ) = @_;
      $m->{fragments}{ $self->name } = $self->_model;
      return $m;
    }
  );
};

before stop => sub {
  my $self = shift;
  debug "Stop encode ", $self->name, " with config ", $self->config;
  em->model->transaction(
    sub {
      my ( $m, $rev ) = @_;
      delete $m->{fragments}{ $self->name };
      return $m;
    }
  );
};

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

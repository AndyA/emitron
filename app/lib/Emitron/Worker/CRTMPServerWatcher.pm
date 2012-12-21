package Emitron::Worker::CRTMPServerWatcher;

use Moose;

use Emitron::BackOff;
use Emitron::CRTMPServer;
use Emitron::Logger;
use JSON;
use Time::HiRes qw( sleep );

extends qw( Emitron::Worker::Base );

has uri => ( isa => 'Str', is => 'ro', required => 1 );

=head1 NAME

Emitron::Worker::CRTMPServerWatcher - Poll crtmpserver

=cut

sub run {
  my $self = shift;

  my $prev    = undef;
  my $srv     = Emitron::CRTMPServer->new( uri => $self->uri );
  my $backoff = Emitron::BackOff->new( base => 1, max => 10 );

  while () {
    my $streams = eval { $srv->api('listStreams') };
    if ( my $err = $@ ) {
      error $err;
      sleep $backoff->bad;
    }
    elsif ($streams) {
      my $next = encode_json $streams;
      unless ( defined $prev && $prev eq $next ) {
        $self->_handle_listStreams($streams);
        $prev = $next;
      }
      sleep $backoff->good;
    }
  }
}

sub _handle_listStreams {
  my ( $self, $data ) = @_;

  # Quick and a little dirty
  $self->em->model->transaction(
    sub {
      my ( $model, $rev ) = @_;
      $model->{streams} = $self->_munge_streams($data);
      return $model;
    }
  );
}

sub _munge_streams {
  my ( $self, $data ) = @_;
  my $out = {};
  for my $app ( keys %$data ) {
    unless ( length $app ) {
      error "Rejecting unnamed app";
      next;
    }
    my $by_type = $data->{$app}{streams} || {};
    for my $type ( keys %$by_type ) {
      unless ( length $type ) {
        error "Rejecting empty type";
        next;
      }
      my $by_name = $by_type->{$type};
      for my $name ( keys %$by_name ) {
        unless ( length $name ) {
          error "Rejecting unnamed stream";
          next;
        }
        my $rec = $by_name->{$name};
        $rec->{rtmp} = $rec->{preview} = $self->_rtmp_url($name);
        $rec->{rtsp} = $self->_rtsp_url($name);
        $out->{$name}{$type}{$app} = $rec;
      }
    }
  }

  return $out;
}

sub _rtsp_url {
  my ( $self, $name ) = @_;
  return $self->em->uri( rtsp_stream => $name );
}

sub _rtmp_url {
  my ( $self, $name ) = @_;
  return $self->em->uri( rtmp_stream => $name );
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

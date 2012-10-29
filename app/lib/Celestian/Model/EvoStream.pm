package Celestian::Model::EvoStream;

use strict;
use warnings;

use Celestian::Logger;
use Celestian::Model::Stream;

use base qw( Celestian::Model::Base );

use constant kind => 'evostream';

use accessors::ro qw( evo );

=head1 NAME

Celestian::Model::EvoStream - An EvoStream instance

=cut

sub on_added {
  my $self = shift;
  my $app  = shift;
  $app->on( 'tick', sub { $self->on_tick } );
}

=for reference

my @stms = [
  {
    queryTimestamp => "1350409195104.01",
    edgePid        => 0,
    audio          => {
      bytesCount          => 790851,
      droppedPacketsCount => 0,
      packetsCount        => 7378,
      droppedBytesCount   => 0
    },
    upTime    => "78993.04",
    bandwidth => 2078,
    video     => {
      bytesCount          => 19038523,
      droppedPacketsCount => 0,
      packetsCount        => 149320,
      droppedBytesCount   => 0
    },
    uniqueId            => 8,
    creationTimestamp   => "1350409116110.97",
    name                => "igloo",
    type                => "INR",
    outStreamsUniqueIds => undef
  }
];

=cut

sub _uniq {
  my %seen = ();
  return grep { !$seen{$_}++ } @_;
}

sub _poll_streams {
  my $self   = shift;
  my @ids    = @{ $self->evo->list_streams_ids->{data} || [] };
  my $known  = $self->{_known} ||= {};
  my %orphan = %$known;

  for my $id ( @ids ) {
    delete $orphan{$id};
    next if $known->{$id};
    $self->add( $known->{$id}
       = Celestian::Model::Stream->new( id => $id, evo => $self->evo )
    );
    debug( "Registering stream $id (",
      $known->{$id}->name, ", ", $known->{$id}->type, ")" );
  }
  for my $oid ( keys %orphan ) {
    debug( "Unregistering stream $oid" );
    $self->remove( delete $known->{$oid} );
  }
}

sub on_tick {
  my $self = shift;
  $self->_poll_streams;
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

package NewStream::Model::Base;

use strict;
use warnings;

use Carp qw( croak );
use Scalar::Util qw( refaddr );

=head1 NAME

NewStream::Model::Base - Base class for model objects

=cut

sub new {
  my $class = shift;
  return bless {}, $class;
}

sub _parse_ev_ns {
  my $ev = shift;
  return ( $1, $2 ) if $ev =~ m{^(.+?):(.+)$};
  return ( 'default', $ev );
}

sub _with_hash {
  my ( $hash, $key, $cb ) = @_;
  return $cb->( $hash, $key ) unless $key eq '*';
  $cb->( $hash, $_ ) for sort keys %$hash;
}

sub _with_event {
  my $self = shift;
  my ( $ev, $cb )  = @_;
  my ( $ns, $evn ) = _parse_ev_ns( $ev );
  _with_hash(
    $self->{_handler},
    $evn,
    sub {
      my ( $h, $k ) = @_;
      for my $hdlr ( @{ $h->{$k} } ) {
        $cb->( $hdlr->[0], $k ) if $ns eq '*' || $ns eq $hdlr->[0];
      }
    }
  );
}

sub list_event_handlers {
  my $self = shift;

  my @eh = ();
  $self->_with_event( '*:*', sub { push @eh, join ':', @_ } );
  return @eh;
}

sub on {
  my $self = shift;
  croak "Need a number of event => handler pairs" if @_ % 2;
  while ( my ( $ev, $hdlr ) = splice @_, 0, 2 ) {
    my ( $ns, $evn ) = _parse_ev_ns( $ev );
    push @{ $self->{_handler}{$evn} }, [ $ns, $hdlr ];
  }
}

sub off {
  my $self = shift;
  for my $ev ( @_ ) {
    my ( $ns, $evn ) = _parse_ev_ns( $ev );
    _with_hash(
      $self->{_handler},
      $evn,
      sub {
        my ( $h, $k ) = @_;
        $self->{_handler}{$k}
         = ( $ns eq '*' )
         ? []
         : [ grep { $_->[0] ne $ns } @{ $self->{_handler}{$k} } ];
      }
    );
  }
}

sub raise {
  my $self = shift;
  my ( $ev, @args ) = @_;
  $_->[1]( @args ) for @{ $self->{_handler}{$ev} ||= [] };
}

sub _find_obj {
  my $self = shift;
  my $obj  = shift;
  return $self->{_index}{ refaddr $obj};
}

sub on_added   { }
sub on_removed { }

sub _add {
  my $self = shift;
  my ( $kind, $obj ) = @_;
  return if $self->_find_obj( $obj );
  my $ol = $self->{_obj}{$kind} ||= [];
  $self->{_index}{ refaddr $obj } = [ $kind, scalar @$ol ];
  push @$ol, $obj;
  $obj->on_added( $self );
  $self->raise( "added_$kind" => $obj );
  $self->raise( added => $kind, $obj );
}

sub _remove {
  my $self = shift;
  my $obj  = shift;
  my $loc  = $self->_find_obj( $obj );
  return unless $loc;
  my ( $kind, $idx ) = @$loc;
  $self->raise( removed => $kind, $obj );
  $self->raise( "removed_$kind", $obj );
  $obj->on_removed( $self );
  splice @{ $self->{_obj}{$kind} }, $idx, 1;
  delete $self->{_index}{ refaddr $obj};
}

sub add {
  my $self = shift;
  for my $obj ( @_ ) {
    croak "Attempt to add something that doesn't respond to 'kind'"
     unless UNIVERSAL::can( $obj, 'can' ) && $obj->can( 'kind' );
    my $kind = $obj->kind;
    $self->_add( $kind, $obj );
  }
}

sub remove {
  my $self = shift;
  $self->_remove( $_ ) for @_;
}

sub each_kind {
  my $self = shift;
  my $cb   = shift;
  my $objs = $self->{_obj};
  for my $kind ( sort keys %$objs ) {
    $cb->( $kind ) if @{ $objs->{$kind} };
  }
}

sub each {
  my $self = shift;
  my ( $kind, $cb ) = @_;
  for my $obj ( @{ $self->{_obj}{$kind} ||= [] } ) {
    $cb->( $obj );
  }
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

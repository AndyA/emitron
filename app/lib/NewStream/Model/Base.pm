package NewStream::Model::Base;

use strict;
use warnings;

use Carp qw( croak );
use Scalar::Util qw( refaddr );

use NewStream::Logger;
use NewStream::Model::Selection;

=head1 NAME

NewStream::Model::Base - Base class for model objects

=cut

sub new {
  my $class = shift;
  my %opts  = @_;
  return bless {%opts}, $class;
}

### Events ###

sub _parse_ev_ns {
  my $ev = shift;
  return ( $1, $2 ) if $ev =~ m{^(.+?):(.+)$};
  return ( 'default', $ev );
}

sub _witheach_hash {
  my ( $hash, $key, $cb ) = @_;
  return $cb->( $hash, $key ) unless $key eq '*';
  $cb->( $hash, $_ ) for sort keys %$hash;
}

sub _witheach_event {
  my $self = shift;
  my ( $ev, $cb )  = @_;
  my ( $ns, $evn ) = _parse_ev_ns( $ev );
  _witheach_hash(
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
  $self->_witheach_event( '*:*', sub { push @eh, join ':', @_ } );
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
    _witheach_hash(
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

### Collections ###

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
  debug( "added:\n", $obj );
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
  debug( "removed:\n", $obj );
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

sub witheach_kind {
  my $self = shift;
  my $cb   = shift;
  my $objs = $self->{_obj};
  for my $kind ( sort keys %$objs ) {
    $cb->( $kind ) if @{ $objs->{$kind} };
  }
}

sub witheach_of {
  my $self = shift;
  my ( $kind, $cb ) = @_;
  $cb->( $kind, $_ ) for @{ $self->{_obj}{$kind} ||= [] };
}

sub witheach {
  my $self = shift;
  my $cb   = shift;
  $self->witheach_kind( sub { $self->witheach_of( $_[0], $cb ) } );
}

### Selectors ###

sub _hash_to_filter {
  my $h    = shift;
  my @term = ();
  while ( my ( $k, $pred ) = each %$h ) {
    push @term, sub {
      my $obj = shift;
      my $val
       = ( UNIVERSAL::can( $obj, 'can' ) && $obj->can( $k ) )
       ? $obj->$k()
       : $obj->{$k};
      return 'CODE' eq ref $pred ? $pred->( $val ) : $pred eq $val;
    };
  }
  return sub { 1 }
   if @term == 0;
  return $term[0] if @term == 1;
  return sub {
    my $obj = shift;
    for my $t ( @term ) {
      return unless $t->( $obj );
    }
    return 1;
  };
}

sub select {
  my $self = shift;
  return $self unless @_;
  return NewStream::Model::Selection->_new( $self,
    _hash_to_filter( {@_} ) );
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

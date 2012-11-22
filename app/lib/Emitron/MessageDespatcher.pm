package Emitron::MessageDespatcher;

use strict;
use warnings;

use Emitron::Logger;

=head1 NAME

Emitron::MessageDespatcher - Despatch messages

=cut

sub new {
  my $class = shift;
  return bless { @_, h => [] }, $class;
}

sub _wild_to_re {
  my ( $self, $match ) = @_;
  return $match if 'Regexp' eq ref $match;
  return $match unless $match =~ /\*/;
  my $re = join '([^\\.]+)', map quotemeta, split /\*/, $match, -1;
  return qr{^$re$};
}

sub on {
  my ( $self, $name, $handler, $group ) = @_;
  defined $group or $group = 'global';
  push @{ $self->{h} },
   {
    name    => "$name",
    match   => $self->_wild_to_re( $name ),
    handler => $handler,
    group   => $group
   };
  return $self;
}

sub _match {
  my ( $self, $h, $like ) = @_;
  return if defined $like->{name}  && $like->{name}  ne $h->{name};
  return if defined $like->{group} && $like->{group} ne $h->{group};
  return 1;
}

sub off {
  my ( $self, %like ) = @_;
  @{ $self->{h} }
   = grep { !$self->_match( $_, \%like ) } @{ $self->{h} };
  return $self;
}

sub _bind_message {
  my ( $self, $name ) = @_;
  my @hh = ();
  for my $h ( @{ $self->{h} } ) {
    my @cap = ();
    my $ma  = $h->{match};
    push @hh, [ $h, @cap ]
     if ( 'Regexp' eq ref $ma && ( @cap = $name =~ $ma ) )
     || $ma eq $name;
  }
  return @hh;
}

sub despatch {
  my ( $self, $msg ) = @_;

  my @hh = $self->_bind_message( $msg->type );
  for my $hh ( @hh ) {
    my $h = shift @$hh;
    $h->{handler}( $msg, @$hh );
  }
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

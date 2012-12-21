package Emitron::MessageDespatcher;

use Moose;

use Emitron::Logger;

=head1 NAME

Emitron::MessageDespatcher - Despatch messages

=cut

sub BUILD {
  my $self = shift;
  $self->{md_h} = [];
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
  push @{ $self->{md_h} },
   {name    => "$name",
    match   => $self->_wild_to_re($name),
    handler => $handler,
    group   => $group
   };
  return $self;
}

sub _match {
  my ( $self, $h, $like ) = @_;
  return if defined $like->{name}  && $like->{name} ne $h->{name};
  return if defined $like->{group} && $like->{group} ne $h->{group};
  return 1;
}

sub off {
  my ( $self, %like ) = @_;
  my @nh = grep { !$self->_match( $_, \%like ) } @{ $self->{md_h} };
  if ( scalar @nh != scalar @{ $self->{md_h} } ) {
    @{ $self->{md_h} } = @nh;
    delete $self->{md_c};
  }
  return $self;
}

sub _map_message {
  my ( $self, $name ) = @_;
  my @hh = ();
  for my $h ( @{ $self->{md_h} } ) {
    my @cap = ();
    my $ma  = $h->{match};
    push @hh, [$h, @cap]
     if ( 'Regexp' eq ref $ma && ( @cap = $name =~ $ma ) )
     || $ma eq $name;
  }
  return \@hh;
}

sub _bind_message {
  my ( $self, $name ) = @_;
  return @{ $self->{md_c}{$name} ||= $self->_map_message($name) };
}

sub despatch {
  my ( $self, $msg ) = @_;
  debug "Despatching: ", $msg->type;
  my @hh = $self->_bind_message( $msg->type );
  info "Unhandled message: ", $msg->type unless @hh;
  for my $hh (@hh) {
    my ( $h, @a ) = @$hh;
    $h->{handler}( $msg, @a );
  }
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

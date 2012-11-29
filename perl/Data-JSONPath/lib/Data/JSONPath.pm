package Data::JSONPath;

use warnings;
use strict;

=head1 NAME

Data::JSONPath - Compute and apply JSONJSONPath compatible deltas

=head1 VERSION

This document describes Data::JSONPath version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

  use Data::JSONPath;
  
=head1 DESCRIPTION

  http://goessner.net/articles/JsonPath/
  http://tools.ietf.org/html/draft-pbryan-json-patch-00

=head1 INTERFACE 

=cut

sub nibbler {
  my ( $class, $str, @tokmatch ) = @_;
  return sub {
    return if defined pos $str && pos $str == length $str;
    for my $tm ( @tokmatch, { re => qr{.+}, t => 'unknown' } ) {
      if ( my @m = ( $str =~ /\G($tm->{re})/gc ) ) {
        return { t => $tm->{t}, m => \@m };
      }
    }
  };
}

sub toker {
  my ( $class, $path ) = @_;
  my %ESCMAP = (
    "b"  => "\b",
    "f"  => "\f",
    "n"  => "\n",
    "r"  => "\r",
    "t"  => "\t",
    "'"  => "'",
    "\"" => "\"",
    "\\" => "\\"
  );

  my $ESC = qr{ \\ ( [bfnrtv"'\\] 
                   | [0-3][0-7]{2}
                   | x[0-9a-fA-F]{2}
                   | u[0-9a-fA-F]{4} ) }x;

  my @TOKMATCH = (
    { re => qr{\d+:\d+(?::\d+)?},   t => 'slice' },
    { re => qr{(\w+|\$)},           t => 'lit' },
    { re => qr{\.\.},               t => 'dotdot' },
    { re => qr{\.},                 t => 'dot' },
    { re => qr{\*},                 t => 'star' },
    { re => qr{@},                  t => 'at' },
    { re => qr{\[},                 t => 'lb' },
    { re => qr{\]},                 t => 'rb' },
    { re => qr{,},                  t => 'comma' },
    { re => qr{\?\(},               t => 'lpq' },
    { re => qr{\(},                 t => 'lp' },
    { re => qr{\)},                 t => 'rp' },
    { re => qr{"(([^\\"]+|\\.)*)"}, t => 'str' },
    { re => qr{'(([^\\']+|\\.)*)'}, t => 'str' }
  );

  my $pp_esc = sub {
    my $esc = shift;
    return $ESCMAP{$esc} if exists $ESCMAP{$esc};
    return chr hex substr $esc, 1 if $esc =~ /^[ux]/;
    return chr oct $esc if $esc =~ /^[0-3]/;
    return '\\' . $esc;
  };

  my $pp_str = sub {
    my $str = shift;
    $str =~ s/($ESC)/$pp_esc->($2)/eg;
    return $str;
  };

  my $nib = $class->nibbler( $path, @TOKMATCH );

  return sub {
    my $tok = $nib->();

    return unless defined $tok;

    if ( $tok->{t} eq 'str' ) {
      return {
        t => 'str',
        m => [ $tok->{m}[0], $pp_str->( $tok->{m}[1] ) ]
      };
    }

    if ( $tok->{t} eq 'slice' ) {
      return {
        t => 'slice',
        m => [ $tok->{m}[0], map $_ * 1, split /:/, $tok->{m}[0] ]
      };
    }

    return $tok;
  };
}

sub new {
  my $class = shift;
  my $self = bless {}, $class;
  $self->parse( @_ ) if @_;
  return $self;
}

sub upgrade {
  my ( $class, $obj ) = @_;
  return $obj if UNIVERSAL::can( $obj, 'isa' ) && $obj->isa( $class );
  return $class->new( $obj );
}

sub _mk_list_iter {
  my @l = @_;
  sub { return shift @l }
}

sub _mk_slice_iter {
  my ( $from, $to, $step ) = @_;
  $step = 1 unless defined $step;
  return sub {
    my $v = $from;
    return if $v >= $to;
    $from += $step;
    return $v;
  };
}

sub _mk_slice {
  my $tok = shift;
  my ( undef, $from, $to, $step ) = @{ $tok->{m} };
  $step = 1 unless defined $step;
  return {
    match => sub {
      $_[0] >= $from && $_[0] < $to && ( $_[0] - $from ) % $step == 0;
    },
    iter    => sub { _mk_slice_iter( $from, $to, $step ) },
    capture => 1,
  };
}

sub _mk_literal {
  my $tok = shift;
  my $vv  = $tok->{m}[1];
  return {
    match => sub { return $_[0] eq $vv },
    iter => sub { _mk_list_iter( $vv ) },
    capture => 0
  };
}

sub _mk_any {
  my $tok = shift;
  return {
    match => sub { 1 },
    iter  => sub {
      my $obj = shift;
      return _mk_slice_iter( 0, scalar @$obj ) if 'ARRAY' eq ref $obj;
      return _mk_list_iter( sort keys %$obj ) if 'HASH' eq ref $obj;
      return sub { };
    },
    capture => 1,
  };
}

sub _mk_multi_iter {
  my ( $obj, @pp ) = @_;
  my $ipos = 0;
  my $ii   = $pp[ $ipos++ ]{iter}( $obj );
  return sub {
    while () {
      my $vv = $ii->();
      return $vv if defined $vv;
      return if $ipos >= @pp;
      $ii = $pp[ $ipos++ ]{iter}( $obj );
    }
  };
}

sub _mk_multi {
  my @pp = @{ $_[0] };
  die "Empty []" unless @pp;
  return $pp[0] if @pp == 1;
  return {
    match => sub {
      my $key = shift;
      for my $p ( @pp ) { return 1 if $p->{match}( $key ) }
      return;
    },
    iter    => sub { _mk_multi_iter( $_[0], @pp ) },
    capture => 1,
  };
}

sub _parse_brackets {
  my ( $class, $tokr ) = @_;

  my @pp = ();

  my %TOKH = (
    lit   => \&_mk_literal,
    str   => \&_mk_literal,
    slice => \&_mk_slice,
    star  => \&_mk_any,
  );

  my $tok = $tokr->();
  while ( $tok ) {
    my $th = $TOKH{ $tok->{t} } or die "Syntax error: ", $tok->{m}[0];
    push @pp, $th->( $tok );
    $tok = $tokr->();
    die "Missing ]" unless $tok;
    last if $tok->{t} eq 'rb';
    die "Syntax error: ", $tok->{m}[0] unless $tok->{t} eq 'comma';
    $tok = $tokr->();
  }
  return \@pp;
}

sub _parse {
  my ( $class, $path ) = @_;
  my $tokr = $class->toker( $path );
  my @pp   = ();

  my %TOKH = (
    lit  => \&_mk_literal,
    star => \&_mk_any,
    dot  => sub { },
    lb   => sub { _mk_multi( $class->_parse_brackets( $tokr ) ) },
  );

  my $tok = $tokr->();
  die "Empty path" unless defined $tok;
  while ( $tok ) {
    my $th = $TOKH{ $tok->{t} } or die "Syntax error: ", $tok->{m}[0];
    push @pp, $th->( $tok );
    $tok = $tokr->();
  }
  return \@pp;
}

sub parse {
  my ( $self, $path ) = @_;
  my $cl = ref $self;
  return $self->{path} = $cl->_parse( $path ) if $cl;
  return $self->_parse( $path );
}

sub _split_simple {
  my ( $self, $path ) = @_;
  return split /\./, $path if $path =~ /^\$(?:\.\w+)*$/;
  die "Needs a simple path";
}

sub path { @{ shift->{path} || [] } }

sub match {
  my ( $self, $path ) = @_;
  my @mp = $self->_split_simple( $path );
  my @pp = $self->path;
  while ( @pp && @mp ) {
    return unless ( shift @pp )->{match}( shift @mp );
  }
  return if @pp;
  return \@mp;
}

sub capture {
  my ( $self, $path ) = @_;
  my @mp  = $self->_split_simple( $path );
  my @pp  = $self->path;
  my @cap = ();
  while ( @pp && @mp ) {
    my $mv = shift @mp;
    push @cap, $mv if ( shift @pp )->{capture};
  }
  return \@cap;
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl


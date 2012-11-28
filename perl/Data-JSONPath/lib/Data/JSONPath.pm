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

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl


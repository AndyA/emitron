package Data::JSONDiff;

use strict;
use warnings;

use List::Util qw( min );

use base qw( Exporter );

our @EXPORT = qw( json_diff );

=head1 NAME

Data::JSONDiff - Produce a JSONDiff of two data structures

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

  use Data::JSONDiff;
  
  my $d1 = { foo => 1, bar => 2 };
  my $d2 = { foo => 3, bar => 4 };
  my $patch = json_diff($d1, $d2);
  
=head1 DESCRIPTION

  http://goessner.net/articles/JsonPath/
  http://tools.ietf.org/html/draft-pbryan-json-patch-00

=head1 INTERFACE 

=head2 C<< json_diff >>

  my $diff = json_diff($data_a, $data_b);

=cut

sub json_diff {
  my ( $da, $db ) = @_;
  my @diff = ();
  _diff(
    $da, $db,
    sub {
      my ( $verb, @path ) = @_;
      if ( $verb eq 'add' ) {
        my $v   = pop @path;
        my $elt = pop @path;
        push @diff,
         {
          op => 'add',
          ( @path ? ( path => join( '.', @path ) ) : () ),
          element => $elt,
          value   => $v
         };
      }
      elsif ( $verb eq 'remove' ) {
        push @diff,
         {
          op   => 'remove',
          path => join( '.', @path ),
         };
      }
    },
    '$'
  );
  return \@diff;
}

sub _uniq {
  my %seen = ();
  return grep { !$seen{$_}++ } @_;
}

sub _diff {
  my ( $da, $db, $cb, @path ) = @_;
  my $ra = ref $da;
  my $rb = ref $db;

  if ( $ra && $rb && $ra eq $rb ) {
    if ( 'HASH' eq $ra ) {
      my @k = _uniq( keys %$da, keys %$db );
      for my $k ( @k ) {
        if ( exists $da->{$k} ) {
          if ( exists $db->{$k} ) {
            _diff( $da->{$k}, $db->{$k}, $cb, @path, $k );
          }
          else {
            $cb->( 'remove', @path, $k );
          }
        }
        else {
          $cb->( 'add', @path, $k, $db->{$k} );
        }
      }
      return;
    }

    if ( 'ARRAY' eq $ra ) {
      my $la = scalar @$da;
      my $lb = scalar @$db;
      my $mi = min( $la, $lb );
      for my $i ( 0 .. $mi - 1 ) {
        _diff( $da->[$i], $db->[$i], $cb, @path, $i );
      }
      for ( my $i = $la; $i < $lb; $i++ ) {
        $cb->( 'add', @path, $i, $db->[$i] );
      }
      for ( my $i = $lb; $i < $la; $i++ ) {
        $cb->( 'remove', @path, $lb );
      }
      return;
    }

    confess( "I don't know how to handle a $ra" );
  }

  return if !defined $da && !defined $db;
  return if !$ra && !$rb && defined $da && defined $db && $da eq $db;

  $cb->( 'remove', @path );
  $cb->( 'add', @path, $db );
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

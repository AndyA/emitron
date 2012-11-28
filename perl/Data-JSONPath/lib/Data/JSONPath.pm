package Data::JSONPath;

use warnings;
use strict;

use Carp qw( confess croak );
use Storable qw( dclone );

use base qw( Exporter );

our @EXPORT_OK = qw( data_diff data_patch data_patched );

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

sub _at_path {
  my ( $data, $cb, $k, @path ) = @_;
  return $cb->( $data, $k ) unless @path;
  croak "JSONPath refers to a non-existant path"
   unless defined $data && ref $data;
  return _at_path( $data->{$k}, $cb, @path ) if 'HASH'  eq ref $data;
  return _at_path( $data->[$k], $cb, @path ) if 'ARRAY' eq ref $data;
  confess( "I don't know how to handle a " . ref $data );
}

=head2 C<< data_patch >>

  data_patch($data_a, $diff);

=cut

sub data_patch {
  my ( $orig, $patch ) = @_;
  my $data = { '$' => $orig };
  for my $p ( @$patch ) {
    my @path = map { split /\./ }
     grep { defined } @{$p}{ 'path', 'element' };
    if ( $p->{op} eq 'add' ) {
      my $v = $p->{value};
      _at_path(
        $data,
        sub {
          my ( $data, $k ) = @_;
          if ( 'HASH' eq ref $data ) { $data->{$k} = $v }
          elsif ( 'ARRAY' eq ref $data ) { splice $data, $k, 0, $v }
          else                           { confess }
        },
        @path
      );
    }
    elsif ( $p->{op} eq 'remove' ) {
      _at_path(
        $data,
        sub {
          my ( $data, $k ) = @_;
          if    ( 'HASH'  eq ref $data ) { delete $data->{$k} }
          elsif ( 'ARRAY' eq ref $data ) { splice $data, $k, 1 }
          else                           { confess }
        },
        @path
      );
    }
    else {
      croak "Bad op: $p->{op}";
    }
  }
  return $data->{'$'};
}

=head2 C<< data_patched >>

  my $data_b = data_patched($data_a, $diff);

=cut

sub _clone {
  return dclone $_[0] if ref $_[0];
  return $_[0];
}

sub data_patched {
  my ( $orig, $patch ) = @_;
  return data_patch( _clone( $orig ), $patch );
}

1;
__END__

=head1 CONFIGURATION AND ENVIRONMENT
  
Data::JSONPath requires no configuration files or environment variables.

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-tie-filesystem-dynamic@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Andy Armstrong  C<< <andy@hexten.net> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, Andy Armstrong  C<< <andy@hexten.net> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

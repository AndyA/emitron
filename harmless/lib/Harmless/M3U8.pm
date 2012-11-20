package Harmless::M3U8;

use strict;
use warnings;

use Harmless::M3U8::Formatter;
use Harmless::M3U8::Parser;
use Path::Class;

use Carp qw( croak );

=head1 NAME

Harmless::M3U8 - An M3U8 file

=cut

sub new {
  my $class = shift;
  return bless { @_, _pl => {} }, $class;
}

sub format {
  scalar Harmless::M3U8::Formatter->new->format( shift->{_pl} );
}

sub parse {
  my ( $self, $m3u8 ) = @_;
  $self->{_pl} = Harmless::M3U8::Parser->new->parse( $m3u8 );
  $self;
}

sub read {
  my ( $self, $file ) = @_;
  $self->{_pl} = Harmless::M3U8::Parser->new->parse_file( $file );
  $self;
}

sub write {
  my ( $self, $file ) = @_;
  my $m3u8 = Harmless::M3U8::Formatter->new->format( $self->{_pl} );
  my $tmp  = "$file.tmp";
  print { file( $tmp )->openw } $m3u8;
  rename $tmp, $file or croak "Can't rename $tmp as $file: $!";
  $self;
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

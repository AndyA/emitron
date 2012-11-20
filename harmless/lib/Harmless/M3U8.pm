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
  return bless {
    @_,
    _pl => {
      seg => [ [] ],
      meta   => {},
      vpl    => [],
      closed => 0
    }
   },
   $class;
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

sub cleanup {
  my ( $self, $segs ) = @_;
  my @runs = @{ $self->{_pl}{seg} };
  my @out  = ();
  while ( $segs > 0 && @runs ) {
    my $run = pop @runs;
    $segs -= @$run;
    splice @$run, 0, -$segs if $segs < 0;
    unshift @out, $run;
  }
  $self->{_pl}{seg} = \@out;
  $self;
}

sub segment_count {
  my $self  = shift;
  my $count = 0;
  for my $run ( @{ $self->{_pl}{seg} } ) {
    $count += @$run;
  }
  return $count;
}

sub push_segment {
  my ( $self, @seg ) = @_;
  push @{ $self->{_pl}{seg}[-1] }, @seg;
  $self;
}

sub push_discontinuity {
  my $self = shift;
  my $seg  = $self->{_pl}{seg};
  push @$seg, [] if @$seg;
  $self;
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

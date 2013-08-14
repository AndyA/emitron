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
      seg    => [[]],
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
  $self->{_pl} = Harmless::M3U8::Parser->new->parse($m3u8);
  $self;
}

sub read {
  my ( $self, $file ) = @_;
  $self->{_pl} = Harmless::M3U8::Parser->new->parse_file($file);
  $self;
}

sub write {
  my ( $self, $file ) = @_;
  my $m3u8 = Harmless::M3U8::Formatter->new->format( $self->{_pl} );
  my $tmp  = "$file.tmp";
  print { file($tmp)->openw } $m3u8;
  rename $tmp, $file or croak "Can't rename $tmp as $file: $!";
  $self;
}

sub cleanup {
  my ( $self, $segs ) = @_;
  my @runs = @{ $self->seg };
  my @out  = ();
  while ( $segs > 0 && @runs ) {
    my $run = pop @runs;
    $segs -= @$run;
    splice @$run, 0, -$segs if $segs < 0;
    unshift @out, $run;
  }
  $self->seg( \@out );
  $self;
}

sub segment_count {
  my $self  = shift;
  my $count = 0;
  for my $run ( @{ $self->seg } ) {
    $count += @$run;
  }
  return $count;
}

sub sequence { shift->meta->{EXT_X_MEDIA_SEQUENCE} || 0 }

sub segment_index {
  my ( $self, $pos ) = @_;
  my $segs = $self->seg;
  for my $rn ( 0 .. $#$segs ) {
    my $sz = @{ $segs->[$rn] };
    return ( $rn, $pos ) if $pos < $sz;
    $pos -= $sz;
  }
  return;
}

sub rotate {
  my ( $self, $segs ) = @_;
  my $before = $self->segment_count;
  $self->cleanup(100);
  my $after = $self->segment_count;
  $self->meta->{EXT_X_MEDIA_SEQUENCE} += ( $before - $after );
  $self;
}

sub push_segment {
  my ( $self, @seg ) = @_;
  push @{ $self->seg->[-1] }, @seg;
  $self;
}

sub push_discontinuity {
  my $self = shift;
  my $seg  = $self->seg;
  push @$seg, [] if @{ $seg->[-1] };
  $self;
}

BEGIN {
  my @attr = qw( meta vpl closed seg );
  for my $attr (@attr) {
    no strict 'refs';
    *$attr = sub {
      my $self = shift;
      return $self->{_pl}{$attr} unless @_;
      $self->{_pl}{$attr} = shift;
      $self;
    };
  }
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

package Harmless::M3U8::Parser;

use strict;
use warnings;

use Carp qw( croak );

=head1 NAME

Harmless::M3U8::Parser - Parse M3U8 file

=cut

sub new {
  my $class = shift;
  return bless { @_, _runs => [ [] ] }, $class;
}

sub _str {
  my $v = shift;
  return $v unless $v =~ m{^"(.*)"$};
  my $sv = $1;
  $sv =~ s/\\(.)/$1/g;
  return $sv;
}

sub _parse_attr {
  my $attr  = shift;
  my @at    = ();
  my $id    = qr{[A-Z]+(?:-[A-Z]+)*};
  my $value = qr{"(?:\\.|[^"])*"|[^,]*};
  push @at, $1, _str( $2 ) while $attr =~ m{($id)=($value),?}g;
  return @at;
}

sub make_parser {
  my $self  = shift;
  my $state = 'INIT';
  my $meta  = {};
  my $seg   = undef;

  my $cseg = sub { $seg ||= {} };
  my @segs = ();

  my $pmeta = sub { $meta->{ $_[0] } = $_[1] };

  my %decode = (
    INIT => {
      'EXTM3U' => sub {
        $state = 'HLS';
      },
    },
    HLS => {
      'EXT-X-TARGETDURATION' => $pmeta,
      'EXT-X-VERSION'        => $pmeta,
      'EXT-X-MEDIA-SEQUENCE' => $pmeta,
      'EXT-X-PLAYLIST-TYPE'  => $pmeta,
      'EXTINF'               => sub {
        my ( $dur, $tit ) = split /,/, $_[1], 2;
        $cseg->()->{duration} = $dur;
        $tit = '' unless defined $tit;
        $tit =~ s/\s+$//;
        $cseg->()->{title} = $tit;
      },
      'EXT-X-STREAM-INF' => sub {
        $cseg->()->{ $_[0] } = { _parse_attr( $_[1] ) };
      },
      -uri => sub {
        $cseg->()->{uri} = $_[1];
        push @segs, $seg;
        undef $seg;
      },
    },
  );

  my $despatch = sub {
    my ( $dir, @a ) = @_;
    ( my $nm = lc $dir ) =~ s/^ext-x-//;
    $nm =~ s/-/_/g;
    my $hd = $decode{$state}{$dir};
    $hd->( $nm, @a ) if $hd;
  };

  return sub {
    return { meta => $meta, segments => \@segs } unless @_;
    my $ln = shift;
    return if $ln =~ /^\s*$/;
    if ( $ln =~ /^#(EXT.*)/ ) {
      my $ext = $1;
      $despatch->( $ext =~ /^(.+?):(.*)/ ? ( $1, $2 ) : ( $ext ) );
      return;
    }
    return if $ln =~ /^#/;
    $despatch->( -uri => $ln );
  };
}

sub parse_file {
  my ( $self, $file ) = @_;

  open my $fh, '<', $file
   or croak "Can't read $file: $!";

  my $p = $self->make_parser;

  while ( defined( my $ln = <$fh> ) ) {
    chomp $ln;
    $p->( $ln );
  }

  return $p->();
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

package Harmless::M3U8::Parser;

use strict;
use warnings;

use Carp qw( croak );
use DateTime;
use DateTime::Format::ISO8601;

=head1 NAME

Harmless::M3U8::Parser - Parse M3U8 file

=cut

sub new {
  my $class = shift;
  return bless {@_}, $class;
}

sub _str {
  my $v = shift;
  return $v unless $v =~ m{^"(.*)"$};
  my $sv = $1;
  $sv =~ s/\\(.)/$1/g;
  return $sv;
}

sub _to_name {
  my $s = shift;
  $s =~ s/-/_/g;
  return $s;
}

sub _parse_attr {
  my $attr  = shift;
  my @at    = ();
  my $id    = qr{[A-Z]+(?:-[A-Z]+)*};
  my $value = qr{"(?:\\.|[^"])*"|[^,]*};
  push @at, _to_name($1), _str($2) while $attr =~ m{($id)=($value),?}g;
  return @at;
}

sub make_parser {
  my $self  = shift;
  my $state = 'INIT';

  my $seg = undef;

  my %global = ();

  my $rv = {
    meta   => {},
    vpl    => [],
    seg    => [[]],
    closed => 0,
  };

  my $cseg = sub { $state = $_[0]; $seg ||= {%global} };
  my $pseg = sub { $rv->{seg}[-1][-1] };
  my $pglob = sub { $global{ $_[0] } = { _parse_attr( $_[1] ) }; };
  my $pmeta = sub { $rv->{meta}{ $_[0] } = $_[1] };
  my $pmetaa = sub {
    push @{ $rv->{meta}{ $_[0] } }, { _parse_attr( $_[1] ) };
  };

  my %de_hls = (
    EXT_X_I_FRAME_STREAM_INF => sub {
      $rv->{meta}{ $_[0] } = { _parse_attr( $_[1] ) };
    },
    EXT_X_MAP => $pglob,    # TODO clear map after discontinuity
    EXT_X_KEY => $pglob,

    EXT_X_ALLOW_CACHE    => $pmeta,
    EXT_X_MEDIA_SEQUENCE => $pmeta,
    EXT_X_PLAYLIST_TYPE  => $pmeta,
    EXT_X_TARGETDURATION => $pmeta,
    EXT_X_VERSION        => $pmeta,

    EXT_X_MEDIA              => $pmetaa,
    EXT_X_I_FRAME_STREAM_INF => $pmetaa,

    EXT_X_I_FRAMES_ONLY => sub { $rv->{meta}{ $_[0] } = 1 },
    EXT_X_ENDLIST => sub {
      $rv->{closed} = 1;
      $state = 'IGNORE';
    },
    EXT_X_STREAM_INF => sub {
      $cseg->('HLSPL')->{ $_[0] } = { _parse_attr( $_[1] ) };
    },
    EXT_X_DISCONTINUITY => sub {
      push @{ $rv->{seg} }, [] if @{ $rv->{seg}[-1] };
    },
  );

  my %de_hls_seg = (
    EXTINF => sub {
      my ( $dur, $tit ) = split /,/, $_[1], 2;
      $cseg->('HLSSEG');
      $tit = '' unless defined $tit;
      $tit =~ s/\s+$//;
      $seg->{title}    = $tit;
      $seg->{duration} = $dur;

    },
    EXT_X_PROGRAM_DATE_TIME => sub {
      my $dt = DateTime::Format::ISO8601->parse_datetime( $_[1] );
      $cseg->('HLSSEG')->{ $_[0] }
       = $dt->epoch + $dt->microsecond / 1_000_000;
    },
    EXT_X_BYTERANGE => sub {
      my ( $tag, $arg ) = @_;
      my ( $len, $ofs ) = split /\@/, $arg, 2;
      unless ( defined $ofs ) {
        my $prev = $pseg->()     || die "Need previous segment";
        my $pbr  = $prev->{$tag} || die "Previous segment not byterange";
        $ofs = $pbr->{offset} + $pbr->{length};
      }
      $cseg->('HLSSEG')->{$tag} = {
        length => 1 * $len,
        offset => 1 * $ofs
      };
    },
    uri => sub {
      $cseg->('HLSSEG')->{uri} = $_[1];
      push @{ $rv->{seg}[-1] }, $seg;
      undef $seg;
      $state = 'HLS';
    },
  );

  my %de_hls_pl = (
    uri => sub {
      $cseg->('HLSPL')->{uri} = $_[1];
      push @{ $rv->{vpl} }, $seg;
      undef $seg;
      $state = 'HLS';
    },
  );

  my %decode = (
    INIT => {
      EXTM3U => sub {
        $state = 'HLS';
      },
    },
    HLS    => { %de_hls, %de_hls_seg, },
    HLSSEG => { %de_hls_seg, },
    HLSPL  => { %de_hls_pl, },
  );

  my $despatch = sub {
    my ( $dir, @a ) = @_;
    my $tag = _to_name($dir);
    my $hd  = $decode{$state}{$tag};
    $hd->( $tag, @a ) if $hd;
  };

  return sub {
    return $rv unless @_;
    my $ln = shift;
    return if $ln =~ /^\s*$/;
    if ( $ln =~ /^#(EXT.*)/ ) {
      my $ext = $1;
      $despatch->( $ext =~ /^(.+?):(.*)/ ? ( $1, $2 ) : ($ext) );
      return;
    }
    return if $ln =~ /^#/;
    $despatch->( uri => $ln );
  };
}

sub parse_file {
  my ( $self, $file ) = @_;

  open my $fh, '<', $file
   or croak "Can't read $file: $!";

  my $p = $self->make_parser;

  while ( defined( my $ln = <$fh> ) ) {
    chomp $ln;
    $p->($ln);
  }

  return $p->();
}

sub parse {
  my ( $self, $m3u8 ) = @_;

  my $p = $self->make_parser;

  for my $ln ( split /\n/, $m3u8 ) {
    $p->($ln);
  }

  return $p->();
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

package Harmless::M3U8::Formatter;

use strict;
use warnings;

use DateTime;

=head1 NAME

Harmless::M3U8::Formatter - Format M3U8

=cut

sub new {
  my $class = shift;
  return bless {@_}, $class;
}

sub _from_name {
  my $s = shift;
  $s =~ s/_/-/g;
  return $s;
}

sub _make_tag_formatter {
  my $self = shift;

  my %fs = (
    i   => sub { sprintf '%d', $_[0] },
    f   => sub { sprintf '%g', $_[0] },
    bs  => sub { $_[0] },
    res => sub { $_[0] },
    zqs => sub { qq{"$_[0]"} },
  );

  my $fmtv = sub {
    my ( $type, $val ) = @_;
    if ( 'ARRAY' eq ref $type ) {
      my %ok = map { $_ => 1 } @$type;
      die "Illegal value $val" unless $ok{$val};
      return $val;
    }
    my $f = $fs{$type} || die "No formatter: $type";
    return $f->($val);
  };

  my $stminf = {
    PROGRAM_ID => 'i',
    AUDIO      => 'zqs',
    VIDEO      => 'zqs',
    SUBTITLES  => 'zqs',
    CODECS     => 'zqs',
    RESOLUTION => 'res',
  };

  my %spec = (
    EXT_X_MEDIA_SEQUENCE => 'i',
    EXT_X_TARGETDURATION => 'i',
    EXT_X_VERSION        => 'i',
    EXT_X_PLAYLIST_TYPE  => ['EVENT', 'VOD'],
    EXT_X_MEDIA          => {
      require => {},
      allow   => {
        URI      => 'zqs',
        TYPE     => ['AUDIO', 'VIDEO', 'SUBTITLES'],
        GROUP_ID => 'zqs',
        LANGUAGE => 'zqs',
        NAME     => 'zqs',
        DEFAULT         => ['YES', 'NO'],
        AUTOSELECT      => ['YES', 'NO'],
        FORCED          => ['YES', 'NO'],
        CHARACTERISTICS => 'zqs',
      },
    },
    EXT_X_I_FRAME_STREAM_INF => {
      require => {
        BANDWIDTH => 'i',
        URI       => 'zqs',
      },
      allow => $stminf,
    },
    EXT_X_STREAM_INF => {
      require => { BANDWIDTH => 'i', },
      allow   => $stminf,
    },
    EXT_X_BYTERANGE => sub {
      my $v = shift;
      return join '@', $fmtv->( i => $v->{length} ),
       $fmtv->( i => $v->{offset} );
    },
    EXTINF => sub {
      my $v = shift;
      return join ',', $fmtv->( f => $v->{duration} ),
       $fmtv->( bs => $v->{title} );
    },
    EXT_X_PROGRAM_DATE_TIME => sub {
      my $dt = DateTime->from_epoch( epoch => shift );
      my ( $tm, $tz ) = $dt->strftime( '%FT%T.%3N', '%z' );
      $tz =~ s/^(...)(..)$/$1:$2/;
      return "$tm$tz";
    },
    EXT_X_I_FRAMES_ONLY => [],
  );

  my $fmt = sub {
    my ( $tag, $sp, $val ) = @_;
    my %v       = %$val;
    my %require = %{ $sp->{require} || {} };
    my %allow   = %{ $sp->{allow} || {} };
    my @missing = sort grep { !defined $v{$_} } keys %require;
    die "Missing attributes on $tag: ", join( ', ', @missing )
     if @missing;
    my %all = ( %allow, %require );
    my @ko = sort { $all{$a} cmp $all{$b} || $a cmp $b } keys %all;

    my @out = ();
    for my $k (@ko) {
      my $vv = delete $v{$k};
      push @out, join '=', _from_name($k), $fmtv->( $all{$k}, $vv )
       if defined $vv;
    }
    my @extra = sort keys %v;
    die "Unknown attributes on $tag: ", join( ', ', @extra ) if @extra;
    return join ',', @out;
  };

  my $fmt1 = sub {
    my ( $tag, $val ) = @_;
    my @out = ( '#', _from_name($tag) );
    my $sp = $spec{$tag} || die "Unknown tag: $tag";
    if ( ref $sp ) {
      if ( 'HASH' eq ref $sp ) {
        push @out, ':', $fmt->( $tag, $sp, $val );
      }
      elsif ( 'CODE' eq ref $sp ) {
        push @out, ':', $sp->($val);
      }
      elsif ( 'ARRAY' eq ref $sp ) {
        # Empty array: no value, tag is flag
        # Non-empty array: enum
        push @out, ':', $fmtv->( $sp, $val ) if @$sp;
      }
      else {
        die;
      }
    }
    else {
      push @out, ':', $fmtv->( $sp, $val );
    }

    return join '', @out;
  };

  return sub {
    my ( $tag, $val ) = @_;
    return
     map { $fmt1->( $tag, $_ ) }
     ( ( 'ARRAY' eq ref $val ) ? @$val : ($val) );
  };
}

sub _make_rec_formatter {
  my ( $self, $tf ) = @_;

  return sub {
    my %rec = %{ shift() };
    my @out = ();
    my $uri = delete $rec{uri};
    for my $tag ( sort keys %rec ) {
      push @out, $tf->( $tag, $rec{$tag} );
    }
    push @out, $uri if defined $uri;
    return @out;
  };
}

sub _norm_seg {
  my %seg = %{ shift() };
  my ( $t, $d ) = delete @seg{ 'title', 'duration' };
  $seg{'EXTINF'} = { title => $t, duration => $d }
   if defined $t && defined $d;
  return \%seg;
}

sub format {
  my ( $self, $pl ) = @_;
  my @out = ('#EXTM3U');

  my $tf = $self->_make_tag_formatter;
  my $rf = $self->_make_rec_formatter($tf);

  push @out, $rf->( $pl->{meta} || {} );

  for my $vpl ( @{ $pl->{vpl} || [] } ) {
    push @out, $rf->($vpl);
  }

  for my $run ( @{ $pl->{seg} || [] } ) {
    for my $seg (@$run) {
      push @out, $rf->( _norm_seg($seg) );
    }
    push @out, '#EXT-X-DISCONTINUITY';
  }
  pop @out;    # remove redundant trailing discontinuity

  push @out, '#EXT-X-ENDLIST' if $pl->{closed};

  return wantarray
   ? @out
   : join "\n", @out, '';
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

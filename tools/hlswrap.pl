#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;
use File::Basename qw( basename );
use File::Spec;
use Getopt::Long;
use List::Util qw( min max );
use Time::HiRes qw( sleep );
use XML::LibXML::XPathContext;
use XML::LibXML;

# TODO: Seems we currently undereport the bit rate - probably because
# the first fragment comes up small.

use constant GOP  => 8;
use constant FRAG => '%05d.ts';

my %O = ( live => 0, index => 0, gop => GOP );

GetOptions(
  'live'  => \$O{live},
  'index' => \$O{index},
  'gop:i' => \$O{gop},
) or die;

my $dir = shift
 || die "Please name the directory containing the fragment directories";

my @stm = stm->find_streams( $dir );
die "No streams found" unless @stm;

if ( $O{live} ) { run_live( $dir, @stm ) }
else            { run_vod( $dir, @stm ) }

sub run_live {
  my ( $dir, @stm ) = @_;
  my @on_ready = ( sub { write_root( $dir, @stm ) } );

  $SIG{INT} = sub {
    print "Closing stream\n";
    for my $stm ( @stm ) {
      $stm->close;
      $stm->write_list;
    }
  };

  while () {
    my $got = 0;
    $got += $_->find_frags for @stm;
    if ( @on_ready && lwm( @stm ) > 1 ) {
      $_->() for splice @on_ready;
    }
    sleep $O{gop};
    if ( $got ) {
      $_->write_list for @stm;
    }
  }
}

sub run_vod {
  my ( $dir, @stm ) = @_;
  for my $stm ( @stm ) {
    $stm->find_frags;
    $stm->close;
    $stm->write_list;
  }
  write_root( $dir, @stm );
}

sub write_root {
  my ( $dir, @stm ) = @_;
  write_master( $dir, @stm );
  write_index( $dir ) if $O{index};
}

sub all_frags {
  return map { scalar @{ $_->frags } } @_;
}

sub lwm { min( all_frags( @_ ) ) }

sub write_index {
  my $dir   = shift;
  my $name  = basename $dir;
  my $list  = File::Spec->catfile( $dir, "$name.m3u8" );
  my $index = File::Spec->catfile( $dir, "index.html" );
  return if -f $index;
  open my $fh, '>', $index or die "Can't write $index: $!\n";
  print $fh make_index( $name, "$name.m3u8" );
}

sub write_master {
  my ( $dir, @stm ) = @_;
  my $name = basename $dir;
  my $list = File::Spec->catfile( $dir, "$name.m3u8" );
  my $tmp  = "$list.tmp";
  {
    open my $fh, '>', $tmp or die "Can't write $tmp: $!\n";
    print $fh "#EXTM3U\n";
    my %pl = ();
    for my $stm ( @stm ) {
      my $sd = $stm->dir;
      die unless $sd =~ /(\d+)$/;
      my $idx = $1;
      my $bw  = $stm->bitrate;
      die "Can't get info for stream" unless $bw;
      $pl{$idx} = join "\n",
       "#EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=$bw", $stm->list;
    }
    for my $idx ( sort { $a <=> $b } keys %pl ) {
      print $fh $pl{$idx}, "\n";
    }
  }
  rename $tmp, $list or die "Can't rename $tmp as $list: $!\n";
}

sub stm::find_streams {
  my ( $class, $dir ) = @_;
  my $name = basename $dir;
  my $like = qr{^\Q$name\E-\d+$};
  opendir my $dh, $dir or die "Can't read $dir: $!\n";
  return
   map { $class->new( base => $dir, dir => $_, list => "$_.m3u8", ); }
   sort grep { $_ =~ $like } readdir $dh;
}

sub stm::new {
  my ( $class, %args ) = @_;
  return bless {
    %args,
    frags  => [],
    next   => 1,
    closed => 0,
  }, $class;
}

sub stm::base  { shift->{base} }
sub stm::dir   { shift->{dir} }
sub stm::list  { shift->{list} }
sub stm::next  { shift->{next} }
sub stm::frags { shift->{frags} }

sub stm::frag_file {
  my ( $self, $frag ) = @_;
  return File::Spec->catfile( $self->base, $self->dir, $frag );
}

sub stm::find_frags {
  my $self = shift;
  my $got  = 0;
  while () {
    my $frag = sprintf FRAG, $self->next;
    last unless -f $self->frag_file( $frag );
    $got++;
    $self->{next}++;
    push @{ $self->frags }, join '/', $self->dir, $frag;
    print "Found $frag\n";
  }
  return $got;
}

sub stm::info {
  my $self = shift;
  return $self->{info} ||= do {
    my $frag = $self->frags->[0];
    die unless defined $frag;
    get_info( File::Spec->catfile( $self->base, $frag ) );
  };
}

sub stm::duration {
  return shift->info->{duration};
}

sub stm::bitrate {
  return shift->info->{bitrate};
}

sub stm::write_list {
  my $self = shift;
  my $list = File::Spec->catfile( $self->base, $self->list );
  my $tmp  = "$list.tmp";
  {
    open my $fh, '>', $tmp or die "Can't write $tmp: $!\n";
    print $fh join "\n",
     '#EXTM3U',
     '#EXT-X-VERSION:3',
     '#EXT-X-TARGETDURATION:' . $O{gop},
     '#EXT-X-ALLOW-CACHE:YES',
     '#EXT-X-PLAYLIST-TYPE:EVENT',
     '#EXT-X-MEDIA-SEQUENCE:1', '';
    for my $frag ( @{ $self->frags } ) {
      print $fh join "\n", "#EXTINF:" . $O{gop}, $frag, '';
    }
    print $fh "#EXT-X-ENDLIST\n" if $self->{closed};
  }
  rename $tmp, $list or die "Can't rename $tmp as $list: $!\n";
  print "Updated $list\n";
}

sub stm::close { shift->{closed} = 1 }

sub get_info {
  my $frag  = shift;
  my $lknum = qr{^\d+(?:\.\d+)?$};
  my %find  = (
    duration => { name => 'Duration',         like => $lknum, },
    bitrate  => { name => 'Overall_bit_rate', like => $lknum, },
  );
  my @cmd = ( mediainfo => '--Output=XML', '--Full', $frag );
  my $cmd = join ' ', @cmd;
  open my $ch, '-|', @cmd or die "Can't run mediainfo: $!\n";
  my $mi = do { local $/; <$ch> };
  close $ch or die "$cmd failed: $?\n";
  my $doc = XML::LibXML->load_xml( string => $mi );
  my $xpc = XML::LibXML::XPathContext->new;
  my @gen
   = $xpc->findnodes( "/Mediainfo/File/track[\@type='General']", $doc );

  my %r = ();
  for my $gen ( @gen ) {
    while ( my ( $k, $spec ) = each %find ) {
      for my $nd ( $xpc->findnodes( $spec->{name}, $gen ) ) {
        my $nv = $nd->textContent;
        $r{$k} = $nv if $nv =~ $spec->{like};
      }
    }
  }
  return \%r;
}

sub make_index {
  my ( $title, $media ) = @_;
  return <<EOT
<!DOCTYPE html>
<html>
  <head>
    <title>$title</title>
  </head>
  <body>
    <video controls="controls" >
      <source src="$media" type="application/x-mpegURL" />
    </video>
  </body>
</html>
EOT
}

# vim:ts=2:sw=2:sts=2:et:ft=perl


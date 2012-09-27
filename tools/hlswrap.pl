#!/usr/bin/env perl

use strict;
use warnings;

use File::Basename qw( basename );
use File::Spec;
use Data::Dumper;
use Getopt::Long;
use Time::HiRes qw( sleep );

use constant GOP  => 8;
use constant FRAG => '%05d.ts';

GetOptions() or die;

my $dir = shift
 || die "Please name the directory containing the fragment directories";

my @stm = stm->find_streams( $dir );
while () {
  for my $stm ( @stm ) {
    $stm->write_list if $stm->find_frags;
  }
  sleep GOP / 2;
}

sub stm::find_streams {
  my ( $class, $dir ) = @_;
  my $name = basename $dir;
  my $like = qr{^\Q$name\E-\d+$};
  opendir my $dh, $dir or die "Can't read $dir: $!\n";
  return
   map { $class->new( base => $dir, dir => $_, list => "$_.m3u8", ); }
   grep { $_ =~ $like } readdir $dh;
}

sub stm::new {
  my ( $class, %args ) = @_;
  return bless { %args, frags => [], next => 0 }, $class;
}

sub stm::base { shift->{base} }
sub stm::dir  { shift->{dir} }
sub stm::list { shift->{list} }
sub stm::next { shift->{next} }

sub stm::find_frags {
  my $self = shift;
  my $got  = 0;
  while () {
    my $frag = sprintf FRAG, $self->next;
    my $try = File::Spec->catfile( $self->base, $self->dir, $frag );
    last unless -f $try;
    $got++;
    $self->{next}++;
    push @{ $self->{frags} }, join '/', $self->dir, $frag;
  }
  return $got;
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
     '#EXT-X-TARGETDURATION:20',
     '#EXT-X-ALLOW-CACHE:YES',
     '#EXT-X-MEDIA-SEQUENCE:1', '';
    for my $frag ( @{ $self->{frags} } ) {
      print $fh join "\n", "#EXTINF:" . GOP, $frag, '';
    }
  }
  rename $tmp, $list or die "Can't rename $tmp as $list: $!\n";
}

=for ref

#EXTM3U
#EXT-X-VERSION:3
#EXT-X-TARGETDURATION:20
#EXT-X-ALLOW-CACHE:YES
#EXT-X-MEDIA-SEQUENCE:1
#EXT-X-PROGRAM-DATE-TIME:2012-09-27T15:35:27.073+00:00
#EXTINF:12,
segment_1348760125005_1348760125005_1.ts
#EXTINF:12,
segment_1348760125005_1348760125005_2.ts

=cut

# vim:ts=2:sw=2:sts=2:et:ft=perl


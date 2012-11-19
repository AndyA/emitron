package Harmless::Segment;

use strict;
use warnings;

use XML::LibXML::XPathContext;
use XML::LibXML;

=head1 NAME

Harmless::Segment - An HLS segment

=cut

use accessors::ro qw( filename );

sub new {
  my $class = shift;
  return bless {@_}, $class;
}

sub _mediainfo {
  my $self  = shift;
  my $lknum = qr{^\d+(?:\.\d+)?$};
  my %find  = (
    duration => { name => 'Duration',         like => $lknum, },
    bitrate  => { name => 'Overall_bit_rate', like => $lknum, },
  );
  my @cmd = ( mediainfo => '--Output=XML', '--Full', $self->filename );
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

sub _info {
  my $self = shift;
  return $self->{_info} ||= $self->_mediainfo;
}

sub bitrate  { shift->_info->{bitrate} }
sub duration { shift->_info->{duration} }

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

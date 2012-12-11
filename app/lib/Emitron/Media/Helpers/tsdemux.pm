package Emitron::Media::Helpers::tsdemux;

use Moose;

use Emitron::Media::Programs;
use String::ShellQuote;

=head1 NAME

Emitron::Media::Helpers::tsdemux - A wrapper for tsdemux

=cut

has programs => (
  isa     => 'Emitron::Media::Programs',
  is      => 'ro',
  default => sub { Emitron::Media::Programs->new }
);

=for reference

tsdemux 1.53 AVCHD/Blu-Ray HDMV Transport Stream demultiplexer

Copyright (C) 2009 Anton Burdinuk

clark15b@gmail.com
http://code.google.com/p/tsdemuxer

TS stream detected in tmp/job.orac_pc_hd_lite.16080.1355264720.965/p80/00000001.ts (packet length=188)
pid=256 (0x0100), ch=1, id=1, type=0x1b (264), stream=0xe0, fps=25.00, len=3960ms, fn=100, esfn=100

time: 0 sec

=cut

sub scan {
  my ( $self, $fn ) = @_;
  my $prg = $self->programs;
  my $cmd = shell_quote( $prg->tsdemux, -p => $fn );

  open my $fh, '-|', $prg->bash, -c => "$cmd 2>&1"
   or die "Can't run $cmd: $!\n";
  while ( <$fh> ) {
    chomp( my $ln = $_ );
    next if /^TS\b/;
    next unless $ln =~ /^ .+?=.+? (?: , \s* .+?=.+ )* $/x;
    my $rec = {};
    for my $fld ( split /\s*,\s*/, $ln ) {
      my ( $k, $v ) = split /=/, $fld, 2;
      next
       unless ( my $vv )
       = $v =~ /^((?:0x[0-9a-f]+)|(-?\d+(?:\.\d+)?))/i;
      $vv = oct $vv if $vv =~ /^0/;
      $rec->{$k} = $vv;
    }
    return $rec if exists $rec->{len};
  }
  return;
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

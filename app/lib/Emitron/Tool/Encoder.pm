package Emitron::Tool::Encoder;

use Moose;

extends 'Emitron::Tool::Base';

use Emitron::App;
use Emitron::Logger;
use Emitron::Media::Encoder;
use Path::Class;

has encoder => (
  isa      => 'Emitron::Media::Encoder',
  is       => 'ro',
  required => 1,
  handles  => [ 'start', 'stop' ]
);

=head1 NAME

Emitron::Tool::Encoder - A multi bit rate encoder

=cut

sub prefix { 'stream.encode' }

sub _make_config {
  my ( $msg, $dir ) = @_;
  my %seen = ();
  my @conf = ();
  em->cfg(
    $msg->{config},
    sub {
      my $cfg = shift;
      for my $enc ( @{ $cfg->{encodes} } ) {
        next if $seen{$enc}++;
        my $odir = dir( $dir, $enc );
        $odir->mkpath;
        my $pro = em->cfg( "\$.profiles.encodes.$enc" );
        unless ( defined $pro ) {
          error "Can't find profile: $enc";
          next;
        }
        push @conf,
         {
          name        => $enc,
          destination => "$odir/%08d.ts",
          profile     => $pro
         };
      }
    }
  );
  return \@conf;
}

em->on(
  'msg.stream.encode.*.*.start' => sub {
    my ( $msg, $name, $type ) = @_;
    my $m = $msg->msg;

    my $dir = em->work_dir( $name, $type );
    debug "start encode $name, $type (work dir: $dir)";

    my $enc = Emitron::Media::Encoder->new(
      source => $m->{stream}{rtsp},
      config => _make_config( $msg->msg, $dir ),
      burnin => 1,
      #      dog     => $DOG,
      tmp_dir => $dir
    );

    my $self = __PACKAGE__->new( name => $name, encoder => $enc );

    em->on(
      "evt.stream.encode.$name.$type.stop" => sub {
        my $msg = shift;
        debug "stop encode $name, $type";
        $self->stop;
        em->off_all;
      }
    );

    $self->start;
    debug "Encoder message path is ", $self->msg_path;
  }
);

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

package Emitron::Config;

use Moose;

use FindBin;
use Net::Domain qw( hostfqdn );
use Path::Class;

=head1 NAME

Emitron::Config - Default config data

=head1 INTERFACE 

=head2 C<< config >>

Returns the default config. Actually it returns a complete
default model.

=cut

{
  my %FQDN_MAP = (
    'igloo.fenkle'     => 'newstream.fenkle',
    'ernie.hexten.net' => 'newstream.hexten.net',
  );

  sub _map_fqdn {
    my ( $class, $fqdn ) = @_;
    $FQDN_MAP{$fqdn} || $fqdn;
  }
}

sub config {
  my $class = shift;
  my $fqdn  = $class->_map_fqdn( hostfqdn );
  my $home  = dir( $FindBin::Bin )->parent->parent;
  my $tmp   = dir( $home, 'tmp' );
  $tmp->mkpath;
  my $dog = file( $home, 'art', 'thespace-dog.png' );
  die "Can't find/read $dog" unless -r $dog;
  return {
    config => {
      paths => { tmp => "$tmp" },
      uri   => {
        rtmp_stream => "rtmp://$fqdn/live/%s",
        rtsp_stream => "rtsp://$fqdn:5544/%s",
        home        => 'http://thespace.org',
        crtmpserver => 'http://localhost:6502',
      },
      packagers => { default => { webroot => 'webroot/live/hls' } },
      profiles  => {
        config => {
          thumbnail => { encodes => ['t10'] },
          pc        => {
            encodes => [ 'p30', 'p40', 'p50', 'p60', 'p70' ],
            dog     => "$dog"
          },
          pc_hd => {
            encodes => [ 'p30', 'p40', 'p50', 'p60', 'p70', 'p80' ],
            dog     => "$dog"
          },
          pc_hd_lite => {
            encodes => [ 'p40', 'p60', 'p80' ],
            dog     => "$dog"
          },
        },
        encodes => {
          t10 => {
            v => {
              bitrate => 200_000,
              rate    => 25,
              profile => 'main',
              level   => 3,
              width   => 224,
              height  => 126
            },
            a => {
              bitrate => 96_000,
              profile => 'aac_he',
              rate    => 22_050,
            }
          },
          p10 => {
            v => {
              bitrate => 32_000,
              rate    => 5,
              profile => 'baseline',
              width   => 224,
              height  => 126
            },
            a => {
              bitrate => 24_000,
              profile => 'aac_he',
              rate    => 22_050,
            }
          },
          p20 => {
            v => {
              bitrate => 128_000,
              rate    => 12.5,
              profile => 'baseline',
              level   => 3,
              width   => 400,
              height  => 224
            },
            a => {
              bitrate => 48_000,
              profile => 'aac_lc',
              rate    => 44_100,
            }
          },
          p30 => {
            v => {
              bitrate => 304_000,
              rate    => 25,
              profile => 'baseline',
              level   => 3,
              width   => 400,
              height  => 224
            },
            a => {
              bitrate => 64_000,
              profile => 'aac_lc',
              rate    => 44_100,
            }
          },
          p40 => {
            v => {
              bitrate => 400_000,
              rate    => 25,
              profile => 'main',
              level   => 3,
              width   => 512,
              height  => 288
            },
            a => {
              bitrate => 96_000,
              profile => 'aac_lc',
              rate    => 44_100,
            }
          },
          p50 => {
            v => {
              bitrate => 700_000,
              rate    => 25,
              profile => 'main',
              level   => 3,
              width   => 640,
              height  => 360
            },
            a => {
              bitrate => 96_000,
              profile => 'aac_lc',
              rate    => 44_100,
            }
          },
          p60 => {
            v => {
              bitrate => 1200_000,
              rate    => 25,
              profile => 'main',
              level   => 3,
              width   => 704,
              height  => 396
            },
            a => {
              bitrate => 96_000,
              profile => 'aac_lc',
              rate    => 44_100,
            }
          },
          p70 => {
            v => {
              bitrate => 2016_000,
              rate    => 25,
              profile => 'main',
              level   => 3.1,
              width   => 1024,
              height  => 576
            },
            a => {
              bitrate => 96_000,
              profile => 'aac_lc',
              rate    => 44_100,
            }
          },
          p80 => {
            v => {
              bitrate => 3372_000,
              rate    => 25,
              profile => 'high',
              level   => 4,
              width   => 1280,
              height  => 720
            },
            a => {
              bitrate => 128_000,
              profile => 'aac_lc',
              rate    => 44_100,
            }
          },
          p90 => {
            v => {
              bitrate => 5100_000,
              rate    => 25,
              profile => 'high',
              level   => 4,
              width   => 1920,
              height  => 1080
            },
            a => {
              bitrate => 192_000,
              profile => 'aac_lc',
              rate    => 48_000
            }
          },
        },
      },
    },
  };
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

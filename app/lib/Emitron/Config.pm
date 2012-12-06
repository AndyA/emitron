package Emitron::Config;

use Moose;

use Net::Domain qw( hostfqdn );

=head1 NAME

Emitron::Config - Default config data

=head1 INTERFACE 

=head2 C<< config >>

Returns the default config. Actually it returns a complete
default model.

=cut

sub config {
  my $class = shift;
  my $fqdn  = hostfqdn;
  return {
    config => {
      paths => { tmp => '/tmp/emitron' },
      uri   => {
        rtmp_stream => "rtmp://$fqdn/live/%s",
        rtsp_stream => "rtsp://$fqdn:5544/%s",
        home        => 'http://thespace.org',
        crtmpserver => 'http://localhost:6502',
      },
      profiles => {
        config => {
          thumbnail => { encodes => ['t10'] },
          pc => { encodes => [ 'p30', 'p40', 'p50', 'p60', 'p70' ] },
          pc_hd =>
           { encodes => [ 'p30', 'p40', 'p50', 'p60', 'p70', 'p80' ] },
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
        },
      },
    },
  };
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

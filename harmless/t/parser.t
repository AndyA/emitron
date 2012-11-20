#!perl

use strict;
use warnings;

use Data::Dumper;
use File::Spec;
use Test::More;

use Harmless::M3U8::Parser;

use constant REF => 't/ref';

my @case = (
  {
    source => 'bipbop_4x3_variant/bipbop_4x3_variant.m3u8',
    want   => {
      segments => [
        {
          "EXT-X-STREAM-INF" => {
            CODECS       => "mp4a.40.2, avc1.4d4015",
            "PROGRAM-ID" => 1,
            BANDWIDTH    => 232370
          },
          uri => "gear1/prog_index.m3u8"
        },
        {
          "EXT-X-STREAM-INF" => {
            CODECS       => "mp4a.40.2, avc1.4d401e",
            "PROGRAM-ID" => 1,
            BANDWIDTH    => 649879
          },
          uri => "gear2/prog_index.m3u8"
        },
        {
          "EXT-X-STREAM-INF" => {
            CODECS       => "mp4a.40.2, avc1.4d401e",
            "PROGRAM-ID" => 1,
            BANDWIDTH    => 991714
          },
          uri => "gear3/prog_index.m3u8"
        },
        {
          "EXT-X-STREAM-INF" => {
            CODECS       => "mp4a.40.2, avc1.4d401f",
            "PROGRAM-ID" => 1,
            BANDWIDTH    => 1927833
          },
          uri => "gear4/prog_index.m3u8"
        },
        {
          "EXT-X-STREAM-INF" => {
            CODECS       => "mp4a.40.2",
            "PROGRAM-ID" => 1,
            BANDWIDTH    => 41457
          },
          uri => "gear0/prog_index.m3u8"
        }
      ],
      meta => {}
    },
  },
  {
    source => 'bipbop_4x3_variant/gear1/prog_index.m3u8',
    want   => {
          segments => [
                        {
                          title => "",
                          duration => "9.9767",
                          uri => "fileSequence0.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence1.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence2.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence3.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence4.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence5.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence6.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence7.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence8.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence9.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence10.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence11.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence12.ts"
                        },
                        {
                          title => "",
                          duration => "9.9767",
                          uri => "fileSequence13.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence14.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence15.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence16.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence17.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence18.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence19.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence20.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence21.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence22.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence23.ts"
                        },
                        {
                          title => "",
                          duration => "9.9767",
                          uri => "fileSequence24.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence25.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence26.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence27.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence28.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence29.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence30.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence31.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence32.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence33.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence34.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence35.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence36.ts"
                        },
                        {
                          title => "",
                          duration => "9.9767",
                          uri => "fileSequence37.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence38.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence39.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence40.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence41.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence42.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence43.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence44.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence45.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence46.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence47.ts"
                        },
                        {
                          title => "",
                          duration => "9.9767",
                          uri => "fileSequence48.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence49.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence50.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence51.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence52.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence53.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence54.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence55.ts"
                        },
                        {
                          title => "",
                          duration => "10.012",
                          uri => "fileSequence56.ts"
                        },
                        {
                          title => "",
                          duration => "9.9417",
                          uri => "fileSequence57.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence58.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence59.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence60.ts"
                        },
                        {
                          title => "",
                          duration => "9.9767",
                          uri => "fileSequence61.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence62.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence63.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence64.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence65.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence66.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence67.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence68.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence69.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence70.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence71.ts"
                        },
                        {
                          title => "",
                          duration => "9.9767",
                          uri => "fileSequence72.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence73.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence74.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence75.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence76.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence77.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence78.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence79.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence80.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence81.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence82.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence83.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence84.ts"
                        },
                        {
                          title => "",
                          duration => "9.9767",
                          uri => "fileSequence85.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence86.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence87.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence88.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence89.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence90.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence91.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence92.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence93.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence94.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence95.ts"
                        },
                        {
                          title => "",
                          duration => "9.9767",
                          uri => "fileSequence96.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence97.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence98.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence99.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence100.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence101.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence102.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence103.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence104.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence105.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence106.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence107.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence108.ts"
                        },
                        {
                          title => "",
                          duration => "9.9767",
                          uri => "fileSequence109.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence110.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence111.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence112.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence113.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence114.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence115.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence116.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence117.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence118.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence119.ts"
                        },
                        {
                          title => "",
                          duration => "9.9767",
                          uri => "fileSequence120.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence121.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence122.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence123.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence124.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence125.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence126.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence127.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence128.ts"
                        },
                        {
                          title => "",
                          duration => "9.9417",
                          uri => "fileSequence129.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence130.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence131.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence132.ts"
                        },
                        {
                          title => "",
                          duration => "9.9767",
                          uri => "fileSequence133.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence134.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence135.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence136.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence137.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence138.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence139.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence140.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence141.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence142.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence143.ts"
                        },
                        {
                          title => "",
                          duration => "9.9767",
                          uri => "fileSequence144.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence145.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence146.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence147.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence148.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence149.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence150.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence151.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence152.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence153.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence154.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence155.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence156.ts"
                        },
                        {
                          title => "",
                          duration => "9.9767",
                          uri => "fileSequence157.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence158.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence159.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence160.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence161.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence162.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence163.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence164.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence165.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence166.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence167.ts"
                        },
                        {
                          title => "",
                          duration => "9.9767",
                          uri => "fileSequence168.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence169.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence170.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence171.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence172.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence173.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence174.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence175.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence176.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence177.ts"
                        },
                        {
                          title => "",
                          duration => "10.01",
                          uri => "fileSequence178.ts"
                        },
                        {
                          title => "",
                          duration => "9.9433",
                          uri => "fileSequence179.ts"
                        },
                        {
                          title => "",
                          duration => "4.2476",
                          uri => "fileSequence180.ts"
                        }
                      ],
          meta => {
                    "EXT-X-MEDIA-SEQUENCE" => 0,
                    "EXT-X-TARGETDURATION" => 11,
                    "EXT-X-VERSION" => 3,
                    "EXT-X-PLAYLIST-TYPE" => "VOD"
                  }
        },
  }
);

plan tests => 4 * @case;

for my $tc ( @case ) {
  my $name = $tc->{source};
  ok my $p = Harmless::M3U8::Parser->new, "$name: new";
  isa_ok $p, 'Harmless::M3U8::Parser';
  my $src = File::Spec->catfile( REF, $tc->{source} );
  my $got = eval { $p->parse_file( $src ) };
  my $err = $@;
  if ( $tc->{want} ) {
    ok !$err, "$name: no error";
    is_deeply $got, $tc->{want}, "$name: parsed"
     or diag dd( [ $got, $tc->{want} ], [ 'got', 'want' ] );
  }
  else {
    ok $err, "$name: error reported";
    like $err, $tc->{want_error}, "$name: error matches";
  }
}

sub dd {
  Data::Dumper->new( @_ )->Indent( 2 )->Quotekeys( 0 )->Useqq( 1 )
   ->Dump;
}

# vim:ts=2:sw=2:et:ft=perl


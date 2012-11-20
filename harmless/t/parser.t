#!perl

use strict;
use warnings;

use Data::Dumper;
use File::Spec;
use Test::More;

use Harmless::M3U8::Parser;

use constant REF => 't/data';

my @case = (
  {
    source => 'simple_root.m3u8',
    want   => {
      vpl => [
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
      seg => [ [] ],
      meta => {}
    },
  },
  {
    source => 'simple_var.m3u8',
    want   => {
      vpl => [],
      seg => [
        [
          {
            duration => "9.9767",
            title    => "",
            uri      => "fileSequence0.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence1.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence2.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence3.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence4.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence5.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence6.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence7.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence8.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence9.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence10.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence11.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence12.ts"
          },
          {
            duration => "9.9767",
            title    => "",
            uri      => "fileSequence13.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence14.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence15.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence16.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence17.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence18.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence19.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence20.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence21.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence22.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence23.ts"
          },
          {
            duration => "9.9767",
            title    => "",
            uri      => "fileSequence24.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence25.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence26.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence27.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence28.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence29.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence30.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence31.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence32.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence33.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence34.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence35.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence36.ts"
          },
          {
            duration => "9.9767",
            title    => "",
            uri      => "fileSequence37.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence38.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence39.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence40.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence41.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence42.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence43.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence44.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence45.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence46.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence47.ts"
          },
          {
            duration => "9.9767",
            title    => "",
            uri      => "fileSequence48.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence49.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence50.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence51.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence52.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence53.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence54.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence55.ts"
          },
          {
            duration => "10.012",
            title    => "",
            uri      => "fileSequence56.ts"
          },
          {
            duration => "9.9417",
            title    => "",
            uri      => "fileSequence57.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence58.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence59.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence60.ts"
          },
          {
            duration => "9.9767",
            title    => "",
            uri      => "fileSequence61.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence62.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence63.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence64.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence65.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence66.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence67.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence68.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence69.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence70.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence71.ts"
          },
          {
            duration => "9.9767",
            title    => "",
            uri      => "fileSequence72.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence73.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence74.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence75.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence76.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence77.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence78.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence79.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence80.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence81.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence82.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence83.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence84.ts"
          },
          {
            duration => "9.9767",
            title    => "",
            uri      => "fileSequence85.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence86.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence87.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence88.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence89.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence90.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence91.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence92.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence93.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence94.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence95.ts"
          },
          {
            duration => "9.9767",
            title    => "",
            uri      => "fileSequence96.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence97.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence98.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence99.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence100.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence101.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence102.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence103.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence104.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence105.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence106.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence107.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence108.ts"
          },
          {
            duration => "9.9767",
            title    => "",
            uri      => "fileSequence109.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence110.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence111.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence112.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence113.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence114.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence115.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence116.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence117.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence118.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence119.ts"
          },
          {
            duration => "9.9767",
            title    => "",
            uri      => "fileSequence120.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence121.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence122.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence123.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence124.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence125.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence126.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence127.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence128.ts"
          },
          {
            duration => "9.9417",
            title    => "",
            uri      => "fileSequence129.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence130.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence131.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence132.ts"
          },
          {
            duration => "9.9767",
            title    => "",
            uri      => "fileSequence133.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence134.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence135.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence136.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence137.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence138.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence139.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence140.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence141.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence142.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence143.ts"
          },
          {
            duration => "9.9767",
            title    => "",
            uri      => "fileSequence144.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence145.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence146.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence147.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence148.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence149.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence150.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence151.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence152.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence153.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence154.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence155.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence156.ts"
          },
          {
            duration => "9.9767",
            title    => "",
            uri      => "fileSequence157.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence158.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence159.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence160.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence161.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence162.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence163.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence164.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence165.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence166.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence167.ts"
          },
          {
            duration => "9.9767",
            title    => "",
            uri      => "fileSequence168.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence169.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence170.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence171.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence172.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence173.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence174.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence175.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence176.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence177.ts"
          },
          {
            duration => "10.01",
            title    => "",
            uri      => "fileSequence178.ts"
          },
          {
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence179.ts"
          },
          {
            duration => "4.2476",
            title    => "",
            uri      => "fileSequence180.ts"
          }
        ]
      ],
      meta => {
        "EXT-X-MEDIA-SEQUENCE" => 0,
        "EXT-X-TARGETDURATION" => 11,
        "EXT-X-VERSION"        => 3,
        "EXT-X-PLAYLIST-TYPE"  => "VOD"
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


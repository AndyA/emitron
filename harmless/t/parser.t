#!perl

use strict;
use warnings;

use Path::Class;
use Test::Differences;
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
      closed => 0,
      meta   => {}
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
        ]
      ],
      closed => 1,
      meta   => {
        "EXT-X-MEDIA-SEQUENCE" => 0,
        "EXT-X-TARGETDURATION" => 11,
        "EXT-X-VERSION"        => 3,
        "EXT-X-PLAYLIST-TYPE"  => "VOD",
      },
    },
  },
  {
    source => 'discontinuity.m3u8',
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
        ],
        [
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
        ]
      ],
      closed => 1,
      meta   => {
        "EXT-X-MEDIA-SEQUENCE" => 0,
        "EXT-X-TARGETDURATION" => 11,
        "EXT-X-VERSION"        => 3,
        "EXT-X-PLAYLIST-TYPE"  => "VOD",
      }
    },
  },
  {
    source => 'byterange.m3u8',
    want   => {
      vpl => [],
      seg => [
        [
          {
            'EXT-X-BYTERANGE' => {
              offset => 0,
              length => 12893,
            },
            duration => "9.9767",
            title    => "",
            uri      => "fileSequence0.ts"
          },
          {
            'EXT-X-BYTERANGE' => {
              offset => 12893,
              length => 12215,
            },
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence0.ts"
          },
          {
            'EXT-X-BYTERANGE' => {
              offset => 12893 + 12215,
              length => 13923,
            },
            duration => "10.01",
            title    => "",
            uri      => "fileSequence0.ts"
          },
          {
            'EXT-X-BYTERANGE' => {
              offset => 12893 + 12215 + 13923,
              length => 12124,
            },
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence0.ts"
          },
        ]
      ],
      closed => 1,
      meta   => {}
    },
  },
  {
    source => 'datetime.m3u8',
    want   => {
      vpl => [],
      seg => [
        [
          {
            'EXT-X-PROGRAM-DATE-TIME' => 1266562463.031,
            duration                  => "9.9767",
            title                     => "",
            uri                       => "fileSequence0.ts"
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
        ]
      ],
      closed => 0,
      meta   => {}
    },
  },
  {
    source => 'endlist.m3u8',
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
        ]
      ],
      closed => 1,
      meta   => {}
    },
  },
  {
    source => 'complex.m3u8',
    want   => {
      vpl => [
        {
          "EXT-X-STREAM-INF" => {
            AUDIO        => "bipbop_audio",
            RESOLUTION   => "416x234",
            CODECS       => "mp4a.40.2, avc1.4d400d",
            SUBTITLES    => "subs",
            "PROGRAM-ID" => 1,
            BANDWIDTH    => 263851
          },
          uri => "gear1/prog_index.m3u8"
        },
        {
          "EXT-X-STREAM-INF" => {
            AUDIO        => "bipbop_audio",
            RESOLUTION   => "640x360",
            CODECS       => "mp4a.40.2, avc1.4d401e",
            SUBTITLES    => "subs",
            "PROGRAM-ID" => 1,
            BANDWIDTH    => 577610
          },
          uri => "gear2/prog_index.m3u8"
        },
        {
          "EXT-X-STREAM-INF" => {
            AUDIO        => "bipbop_audio",
            RESOLUTION   => "960x540",
            CODECS       => "mp4a.40.2, avc1.4d401f",
            SUBTITLES    => "subs",
            "PROGRAM-ID" => 1,
            BANDWIDTH    => 915905
          },
          uri => "gear3/prog_index.m3u8"
        },
        {
          "EXT-X-STREAM-INF" => {
            AUDIO        => "bipbop_audio",
            RESOLUTION   => "1280x720",
            CODECS       => "mp4a.40.2, avc1.4d401f",
            SUBTITLES    => "subs",
            "PROGRAM-ID" => 1,
            BANDWIDTH    => 1030138
          },
          uri => "gear4/prog_index.m3u8"
        },
        {
          "EXT-X-STREAM-INF" => {
            AUDIO        => "bipbop_audio",
            RESOLUTION   => "1920x1080",
            CODECS       => "mp4a.40.2, avc1.4d401f",
            SUBTITLES    => "subs",
            "PROGRAM-ID" => 1,
            BANDWIDTH    => 1924009
          },
          uri => "gear5/prog_index.m3u8"
        },
        {
          "EXT-X-STREAM-INF" => {
            AUDIO        => "bipbop_audio",
            CODECS       => "mp4a.40.2",
            SUBTITLES    => "subs",
            "PROGRAM-ID" => 1,
            BANDWIDTH    => 41457
          },
          uri => "gear0/prog_index.m3u8"
        }
      ],
      seg => [ [] ],
      closed => 0,
      meta   => {
        "EXT-X-I-FRAME-STREAM-INF" => [
          {
            URI          => "gear1/iframe_index.m3u8",
            CODECS       => "avc1.4d400d",
            "PROGRAM-ID" => 1,
            BANDWIDTH    => 28451
          },
          {
            URI          => "gear2/iframe_index.m3u8",
            CODECS       => "avc1.4d401e",
            "PROGRAM-ID" => 1,
            BANDWIDTH    => 181534
          },
          {
            URI          => "gear3/iframe_index.m3u8",
            CODECS       => "avc1.4d401f",
            "PROGRAM-ID" => 1,
            BANDWIDTH    => 297056
          },
          {
            URI          => "gear4/iframe_index.m3u8",
            CODECS       => "avc1.4d401f",
            "PROGRAM-ID" => 1,
            BANDWIDTH    => 339492
          },
          {
            URI          => "gear5/iframe_index.m3u8",
            CODECS       => "avc1.4d401f",
            "PROGRAM-ID" => 1,
            BANDWIDTH    => 669554
          }
        ],
        'EXT-X-MEDIA' => [
          {
            NAME       => "BipBop Audio 1",
            LANGUAGE   => "eng",
            "GROUP-ID" => "bipbop_audio",
            DEFAULT    => "YES",
            AUTOSELECT => "YES",
            TYPE       => "AUDIO"
          },
          {
            URI        => "alternate_audio_aac/prog_index.m3u8",
            NAME       => "BipBop Audio 2",
            LANGUAGE   => "eng",
            "GROUP-ID" => "bipbop_audio",
            DEFAULT    => "NO",
            AUTOSELECT => "NO",
            TYPE       => "AUDIO"
          },
          {
            URI        => "subtitles/eng/prog_index.m3u8",
            LANGUAGE   => "eng",
            NAME       => "English",
            "GROUP-ID" => "subs",
            DEFAULT    => "YES",
            AUTOSELECT => "YES",
            TYPE       => "SUBTITLES",
            FORCED     => "NO"
          },
          {
            URI        => "subtitles/eng_forced/prog_index.m3u8",
            LANGUAGE   => "eng",
            NAME       => "English (Forced)",
            "GROUP-ID" => "subs",
            DEFAULT    => "YES",
            AUTOSELECT => "NO",
            TYPE       => "SUBTITLES",
            FORCED     => "YES"
          },
          {
            URI        => "subtitles/fra/prog_index.m3u8",
            LANGUAGE   => "fra",
            NAME       => "Français",
            "GROUP-ID" => "subs",
            DEFAULT    => "YES",
            AUTOSELECT => "YES",
            TYPE       => "SUBTITLES",
            FORCED     => "NO"
          },
          {
            URI        => "subtitles/fra_forced/prog_index.m3u8",
            LANGUAGE   => "fra",
            NAME       => "Français (Forced)",
            "GROUP-ID" => "subs",
            DEFAULT    => "YES",
            AUTOSELECT => "NO",
            TYPE       => "SUBTITLES",
            FORCED     => "YES"
          },
          {
            URI        => "subtitles/spa/prog_index.m3u8",
            LANGUAGE   => "spa",
            NAME       => "Español",
            "GROUP-ID" => "subs",
            DEFAULT    => "YES",
            AUTOSELECT => "YES",
            TYPE       => "SUBTITLES",
            FORCED     => "NO"
          },
          {
            URI        => "subtitles/spa_forced/prog_index.m3u8",
            LANGUAGE   => "spa",
            NAME       => "Español (Forced)",
            "GROUP-ID" => "subs",
            DEFAULT    => "YES",
            AUTOSELECT => "NO",
            TYPE       => "SUBTITLES",
            FORCED     => "YES"
          },
          {
            URI        => "subtitles/jpn/prog_index.m3u8",
            LANGUAGE   => "jpn",
            NAME       => "日本人",
            "GROUP-ID" => "subs",
            DEFAULT    => "YES",
            AUTOSELECT => "YES",
            TYPE       => "SUBTITLES",
            FORCED     => "NO"
          },
          {
            URI        => "subtitles/jpn_forced/prog_index.m3u8",
            LANGUAGE   => "jpn",
            NAME       => "日本人 (Forced)",
            "GROUP-ID" => "subs",
            DEFAULT    => "YES",
            AUTOSELECT => "NO",
            TYPE       => "SUBTITLES",
            FORCED     => "YES"
          }
        ]
      }
    },
  },
);

plan tests => 4 * @case;

for my $tc ( @case ) {
  my $name = $tc->{source};
  ok my $p = Harmless::M3U8::Parser->new, "$name: new";
  isa_ok $p, 'Harmless::M3U8::Parser';
  my $src = file( REF, $tc->{source} );
  my $got = eval { $p->parse_file( $src ) };
  my $err = $@;
  if ( $tc->{want} ) {
    ok !$err, "$name: no error";
    is_deeply $got, $tc->{want}, "$name: parsed";

  }
  else {
    ok $err, "$name: error reported";
    like $err, $tc->{want_error}, "$name: error matches";
  }
}

# vim:ts=2:sw=2:et:ft=perl


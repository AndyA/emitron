#!perl

use strict;
use warnings;

use Data::Dumper;
use Path::Class;
use Test::Differences;
use Test::More;

use Harmless::M3U8::Parser;

use constant REF => 't/data';

my @case = (
  { source => 'simple_root.m3u8',
    want   => {
      vpl => [
        { EXT_X_STREAM_INF => {
            CODECS     => "mp4a.40.2, avc1.4d4015",
            PROGRAM_ID => 1,
            BANDWIDTH  => 232370
          },
          uri => "gear1/prog_index.m3u8"
        },
        { EXT_X_STREAM_INF => {
            CODECS     => "mp4a.40.2, avc1.4d401e",
            PROGRAM_ID => 1,
            BANDWIDTH  => 649879
          },
          uri => "gear2/prog_index.m3u8"
        },
        { EXT_X_STREAM_INF => {
            CODECS     => "mp4a.40.2, avc1.4d401e",
            PROGRAM_ID => 1,
            BANDWIDTH  => 991714
          },
          uri => "gear3/prog_index.m3u8"
        },
        { EXT_X_STREAM_INF => {
            CODECS     => "mp4a.40.2, avc1.4d401f",
            PROGRAM_ID => 1,
            BANDWIDTH  => 1927833
          },
          uri => "gear4/prog_index.m3u8"
        },
        { EXT_X_STREAM_INF => {
            CODECS     => "mp4a.40.2",
            PROGRAM_ID => 1,
            BANDWIDTH  => 41457
          },
          uri => "gear0/prog_index.m3u8"
        }
      ],
      seg    => [[]],
      closed => 0,
      meta   => {}
    },
  },
  { source => 'simple_var.m3u8',
    want   => {
      vpl => [],
      seg => [[
          { duration => "9.9767",
            title    => "",
            uri      => "fileSequence0.ts"
          },
          { duration => "9.9433",
            title    => "",
            uri      => "fileSequence1.ts"
          },
          { duration => "10.01",
            title    => "",
            uri      => "fileSequence2.ts"
          },
          { duration => "9.9433",
            title    => "",
            uri      => "fileSequence3.ts"
          },
        ]
      ],
      closed => 1,
      meta   => {
        EXT_X_MEDIA_SEQUENCE => 0,
        EXT_X_TARGETDURATION => 11,
        EXT_X_VERSION        => 3,
        EXT_X_PLAYLIST_TYPE  => "VOD",
      },
    },
  },
  { source => 'discontinuity.m3u8',
    want   => {
      vpl => [],
      seg => [[
          { duration => "9.9767",
            title    => "",
            uri      => "fileSequence0.ts"
          },
          { duration => "9.9433",
            title    => "",
            uri      => "fileSequence1.ts"
          },
        ], [
          { duration => "10.01",
            title    => "",
            uri      => "fileSequence2.ts"
          },
          { duration => "9.9433",
            title    => "",
            uri      => "fileSequence3.ts"
          },
        ]
      ],
      closed => 1,
      meta   => {
        EXT_X_MEDIA_SEQUENCE => 0,
        EXT_X_TARGETDURATION => 11,
        EXT_X_VERSION        => 3,
        EXT_X_PLAYLIST_TYPE  => "VOD",
      }
    },
  },
  { source => 'byterange.m3u8',
    want   => {
      vpl => [],
      seg => [[
          { EXT_X_BYTERANGE => {
              offset => 0,
              length => 12893,
            },
            duration => "9.9767",
            title    => "",
            uri      => "fileSequence0.ts"
          },
          { EXT_X_BYTERANGE => {
              offset => 12893,
              length => 12215,
            },
            duration => "9.9433",
            title    => "",
            uri      => "fileSequence0.ts"
          },
          { EXT_X_BYTERANGE => {
              offset => 12893 + 12215,
              length => 13923,
            },
            duration => "10.01",
            title    => "",
            uri      => "fileSequence0.ts"
          },
          { EXT_X_BYTERANGE => {
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
  { source => 'datetime.m3u8',
    want   => {
      vpl => [],
      seg => [[
          { EXT_X_PROGRAM_DATE_TIME => 1266562463.031,
            duration                => "9.9767",
            title                   => "",
            uri                     => "fileSequence0.ts"
          },
          { duration => "9.9433",
            title    => "",
            uri      => "fileSequence1.ts"
          },
          { duration => "10.01",
            title    => "",
            uri      => "fileSequence2.ts"
          },
          { duration => "9.9433",
            title    => "",
            uri      => "fileSequence3.ts"
          },
        ]
      ],
      closed => 0,
      meta   => {}
    },
  },
  { source => 'endlist.m3u8',
    want   => {
      vpl => [],
      seg => [[
          { duration => "9.9767",
            title    => "",
            uri      => "fileSequence0.ts"
          },
          { duration => "9.9433",
            title    => "",
            uri      => "fileSequence1.ts"
          },
        ]
      ],
      closed => 1,
      meta   => {}
    },
  },
  { source => 'complex.m3u8',
    want   => {
      vpl => [
        { EXT_X_STREAM_INF => {
            AUDIO      => "bipbop_audio",
            RESOLUTION => "416x234",
            CODECS     => "mp4a.40.2, avc1.4d400d",
            SUBTITLES  => "subs",
            PROGRAM_ID => 1,
            BANDWIDTH  => 263851
          },
          uri => "gear1/prog_index.m3u8"
        },
        { EXT_X_STREAM_INF => {
            AUDIO      => "bipbop_audio",
            RESOLUTION => "640x360",
            CODECS     => "mp4a.40.2, avc1.4d401e",
            SUBTITLES  => "subs",
            PROGRAM_ID => 1,
            BANDWIDTH  => 577610
          },
          uri => "gear2/prog_index.m3u8"
        },
        { EXT_X_STREAM_INF => {
            AUDIO      => "bipbop_audio",
            RESOLUTION => "960x540",
            CODECS     => "mp4a.40.2, avc1.4d401f",
            SUBTITLES  => "subs",
            PROGRAM_ID => 1,
            BANDWIDTH  => 915905
          },
          uri => "gear3/prog_index.m3u8"
        },
        { EXT_X_STREAM_INF => {
            AUDIO      => "bipbop_audio",
            RESOLUTION => "1280x720",
            CODECS     => "mp4a.40.2, avc1.4d401f",
            SUBTITLES  => "subs",
            PROGRAM_ID => 1,
            BANDWIDTH  => 1030138
          },
          uri => "gear4/prog_index.m3u8"
        },
        { EXT_X_STREAM_INF => {
            AUDIO      => "bipbop_audio",
            RESOLUTION => "1920x1080",
            CODECS     => "mp4a.40.2, avc1.4d401f",
            SUBTITLES  => "subs",
            PROGRAM_ID => 1,
            BANDWIDTH  => 1924009
          },
          uri => "gear5/prog_index.m3u8"
        },
        { EXT_X_STREAM_INF => {
            AUDIO      => "bipbop_audio",
            CODECS     => "mp4a.40.2",
            SUBTITLES  => "subs",
            PROGRAM_ID => 1,
            BANDWIDTH  => 41457
          },
          uri => "gear0/prog_index.m3u8"
        }
      ],
      seg    => [[]],
      closed => 0,
      meta   => {
        EXT_X_I_FRAME_STREAM_INF => [
          { URI        => "gear1/iframe_index.m3u8",
            CODECS     => "avc1.4d400d",
            PROGRAM_ID => 1,
            BANDWIDTH  => 28451
          },
          { URI        => "gear2/iframe_index.m3u8",
            CODECS     => "avc1.4d401e",
            PROGRAM_ID => 1,
            BANDWIDTH  => 181534
          },
          { URI        => "gear3/iframe_index.m3u8",
            CODECS     => "avc1.4d401f",
            PROGRAM_ID => 1,
            BANDWIDTH  => 297056
          },
          { URI        => "gear4/iframe_index.m3u8",
            CODECS     => "avc1.4d401f",
            PROGRAM_ID => 1,
            BANDWIDTH  => 339492
          },
          { URI        => "gear5/iframe_index.m3u8",
            CODECS     => "avc1.4d401f",
            PROGRAM_ID => 1,
            BANDWIDTH  => 669554
          }
        ],
        EXT_X_MEDIA => [
          { NAME       => "BipBop Audio 1",
            LANGUAGE   => "eng",
            GROUP_ID   => "bipbop_audio",
            DEFAULT    => "YES",
            AUTOSELECT => "YES",
            TYPE       => "AUDIO"
          },
          { URI        => "alternate_audio_aac/prog_index.m3u8",
            NAME       => "BipBop Audio 2",
            LANGUAGE   => "eng",
            GROUP_ID   => "bipbop_audio",
            DEFAULT    => "NO",
            AUTOSELECT => "NO",
            TYPE       => "AUDIO"
          },
          { URI        => "subtitles/eng/prog_index.m3u8",
            LANGUAGE   => "eng",
            NAME       => "English",
            GROUP_ID   => "subs",
            DEFAULT    => "YES",
            AUTOSELECT => "YES",
            TYPE       => "SUBTITLES",
            FORCED     => "NO"
          },
          { URI        => "subtitles/eng_forced/prog_index.m3u8",
            LANGUAGE   => "eng",
            NAME       => "English (Forced)",
            GROUP_ID   => "subs",
            DEFAULT    => "YES",
            AUTOSELECT => "NO",
            TYPE       => "SUBTITLES",
            FORCED     => "YES"
          },
          { URI        => "subtitles/fra/prog_index.m3u8",
            LANGUAGE   => "fra",
            NAME       => "Français",
            GROUP_ID   => "subs",
            DEFAULT    => "YES",
            AUTOSELECT => "YES",
            TYPE       => "SUBTITLES",
            FORCED     => "NO"
          },
          { URI        => "subtitles/fra_forced/prog_index.m3u8",
            LANGUAGE   => "fra",
            NAME       => "Français (Forced)",
            GROUP_ID   => "subs",
            DEFAULT    => "YES",
            AUTOSELECT => "NO",
            TYPE       => "SUBTITLES",
            FORCED     => "YES"
          },
          { URI        => "subtitles/spa/prog_index.m3u8",
            LANGUAGE   => "spa",
            NAME       => "Español",
            GROUP_ID   => "subs",
            DEFAULT    => "YES",
            AUTOSELECT => "YES",
            TYPE       => "SUBTITLES",
            FORCED     => "NO"
          },
          { URI        => "subtitles/spa_forced/prog_index.m3u8",
            LANGUAGE   => "spa",
            NAME       => "Español (Forced)",
            GROUP_ID   => "subs",
            DEFAULT    => "YES",
            AUTOSELECT => "NO",
            TYPE       => "SUBTITLES",
            FORCED     => "YES"
          },
          { URI        => "subtitles/jpn/prog_index.m3u8",
            LANGUAGE   => "jpn",
            NAME       => "日本人",
            GROUP_ID   => "subs",
            DEFAULT    => "YES",
            AUTOSELECT => "YES",
            TYPE       => "SUBTITLES",
            FORCED     => "NO"
          },
          { URI        => "subtitles/jpn_forced/prog_index.m3u8",
            LANGUAGE   => "jpn",
            NAME       => "日本人 (Forced)",
            GROUP_ID   => "subs",
            DEFAULT    => "YES",
            AUTOSELECT => "NO",
            TYPE       => "SUBTITLES",
            FORCED     => "YES"
          }
        ] }
    },
  },
  { source => 'iframe_index.m3u8',
    want   => {
      closed => 1,
      vpl    => [],
      seg    => [[
          { EXT_X_BYTERANGE => {
              length => 53016,
              offset => 564
            },
            duration => "3.003",
            title    => "",
            uri      => "main.ts"
          },
          { EXT_X_BYTERANGE => {
              length => 37788,
              offset => 322608
            },
            duration => "3.003",
            title    => "",
            uri      => "main.ts"
          },
          { EXT_X_BYTERANGE => {
              length => 53016,
              offset => 631304
            },
            duration => "3.003",
            title    => "",
            uri      => "main.ts"
          },
          { EXT_X_BYTERANGE => {
              length => 37788,
              offset => 954476
            },
            duration => "3.003",
            title    => "",
            uri      => "main.ts"
          }
        ]
      ],
      meta => {
        EXT_X_I_FRAMES_ONLY  => 1,
        EXT_X_MEDIA_SEQUENCE => 0,
        EXT_X_TARGETDURATION => 10,
        EXT_X_VERSION        => 4,
        EXT_X_PLAYLIST_TYPE  => "VOD"
      }
    },
  },
);

plan tests => 4 * @case;

for my $tc (@case) {
  my $name = $tc->{source};
  ok my $p = Harmless::M3U8::Parser->new, "$name: new";
  isa_ok $p, 'Harmless::M3U8::Parser';
  my $src = file( REF, $tc->{source} );
  my $got = eval { $p->parse_file($src) };
  my $err = $@;
  if ( $tc->{want} ) {
    ok !$err, "$name: no error";
    is_deeply $got, $tc->{want}, "$name: parsed"
     or diag dd( [$got, $tc->{want}], ['got', 'want'] );
  }
  else {
    ok $err, "$name: error reported";
    like $err, $tc->{want_error}, "$name: error matches";
  }
}

sub dd {
  Data::Dumper->new(@_)->Indent(2)->Quotekeys(0)->Useqq(1)->Dump;
}

# vim:ts=2:sw=2:et:ft=perl


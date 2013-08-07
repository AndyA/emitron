#!/usr/bin/env perl

use strict;
use warnings;

use DBI;
use File::Find;
use Image::Size;
use JSON;
use Memoize;
use POSIX qw( strftime );
use Path::Class;
use Time::Local qw( timegm );
use XML::LibXML::XPathContext;
use XML::LibXML;

use constant ELVIS => 'fail/app/public/asset/elvis';
use constant HOST  => 'localhost';
use constant USER  => 'root';
use constant PASS  => '';
use constant DB    => 'elvis';

memoize 'ref_data';

$| = 1;

{
  my $dbh = dbh(DB);

  import_elvis( $dbh, ELVIS );

  $dbh->disconnect;
}

sub import_elvis {
  my ( $dbh, $dir ) = @_;

  find {
    no_chdir => 1,
    wanted   => sub {
      return unless -f && /\.xml$/;
      my $obj = file($_);
      print "\r$obj", ('   ') x 3;
      eval {
        my $rel = $obj->absolute->relative(ELVIS);
        my ( $kind, $base ) = split /\//, $rel;
        ( my $jpg = $obj ) =~ s/\.xml$/.jpg/;
        ( my $id  = $base ) =~ s/\.xml$//;
        my $fh = $obj->openr;
        $fh->binmode(':encoding(cp1252)');
        my $xml = do { local $/; <$fh> };
        parse_elvis(
          sub {
            my $rec = shift;
            import_image( $dbh, $id, $kind, $jpg, $rec );
          },
          $xml
        );
      };
      if ( my $err = $@ ) {
        print "\nERROR: ", trim($err), "\n";
      }
    },
   },
   $dir;
}

sub import_image {
  my ( $dbh, $id, $kind, $jpg, $rec ) = @_;
  die "$jpg is not readable" unless -r $jpg;
  my ( $w, $h, $err ) = imgsize($jpg);
  die $err unless defined $w && defined $h;

  transaction(
    $dbh,
    sub {

      my $img_rec = {
        acno       => $rec->{acno},
        annotation => $rec->{annotation},
        collection_id =>
         ref_data( $dbh, 'elvis_collection', $rec->{collection} ),
        copyright_class_id =>
         ref_data( $dbh, 'elvis_copyright_class', $rec->{copyrightclass} ),
        copyright_holder_id =>
         ref_data( $dbh, 'elvis_copyright_holder', $rec->{copyrightholder} ),
        format_id   => ref_data( $dbh, 'elvis_format',   $rec->{format} ),
        headline    => $rec->{headline},
        height      => $h,
        kind_id     => ref_data( $dbh, 'elvis_kind',     $kind ),
        location_id => ref_data( $dbh, 'elvis_location', $rec->{location} ),
        news_restriction_id =>
         ref_data( $dbh, 'elvis_news_restriction', $rec->{newsrestrictions} ),
        origin_date => cvt_dt( $rec->{origindate} ),
        personality_id =>
         ref_data( $dbh, 'elvis_personality', $rec->{personalities} ),
        photographer_id =>
         ref_data( $dbh, 'elvis_photographer', $rec->{photographer} ),
        subject_id => ref_data( $dbh, 'elvis_subject', $rec->{subject} ),
        width      => $w,
      };

      insert( $dbh, 'elvis_image', $img_rec )
    }
  );
}

sub transaction {
  my ( $dbh, $cb ) = @_;
  $dbh->do('START TRANSACTION');
  eval { $cb->() };
  if ( my $err = $@ ) {
    $dbh->do('ROLLBACK');
    die $err;
  }
  $dbh->do('COMMIT');
}

sub ref_data {
  my ( $dbh, $tbl, $value ) = @_;
  return undef unless defined $value && length $value;
  my ( $sql, @bind ) = make_select( $tbl, { name => $value }, ['id'] );
  my ($id) = $dbh->selectrow_array( $sql, {}, @bind );
  return $id if defined $id;
  insert( $dbh, $tbl, { name => $value } );
  return $dbh->last_insert_id( undef, undef, $tbl, 'id' );
}

sub parse_elvis {
  my ( $cb, $xml ) = @_;
  my $dom = XML::LibXML->load_xml( string => $xml );
  my $xp = XML::LibXML::XPathContext->new($dom);

  for my $img ( $xp->findnodes('/elvisimage') ) {
    $cb->(
      { map { $_->nodeName => $_->textContent } $img->nonBlankChildNodes } );
  }
}

sub cvt_dt {
  my $tm = parse_dt(shift);
  return undef unless defined $tm;
  return fmt_dt($tm);
}

sub fmt_dt { strftime '%Y-%m-%d', gmtime shift }

sub parse_dt {
  my $dt = shift;
  return undef if $dt eq '' || $dt eq '00000000';
  die "Bad date: $dt\n" unless $dt =~ /^(\d\d\d\d)(\d\d)(\d\d)$/;
  my ( $y, $m, $d ) = ( $1, $2, $3 );
  return timegm( 0, 0, 0, $d, $m - 1, $y );
}

sub trim {
  my $s = shift;
  s/^\s+//, s/\s+$// for $s;
  return $s;
}

sub insert {
  my ( $dbh, $tbl, $rec ) = @_;
  my @k = sort keys %$rec;
  my $sql
   = "INSERT INTO `$tbl` ("
   . join( ', ', map "`$_`", @k )
   . ") VALUES ("
   . join( ', ', map '?', @k ) . ")";
  my $sth = $dbh->prepare($sql);
  $sth->execute( @{$rec}{@k} );
}

sub make_where {
  my $sel = shift;
  my ( @bind, @term );
  for my $k ( sort keys %$sel ) {
    my $v = $sel->{$k};
    my ( $op, $vv ) = 'ARRAY' eq ref $v ? @$v : ( '=', $v );
    push @term, "`$k` $op ?";
    push @bind, $vv;
  }
  @term = ('TRUE') unless @term;
  return ( join( ' AND ', @term ), @bind );
}

sub make_select {
  my ( $tbl, $sel, $cols ) = @_;

  my ( $where, @bind ) = make_where($sel);

  my @sql = (
    'SELECT',
    ( $cols ? join ', ', map "`$_`", @$cols : '*' ),
    "FROM `$tbl` WHERE ", $where
  );

  return ( join( ' ', @sql ), @bind );
}

sub show_sql {
  my ( $sql, @bind ) = @_;
  my $next = sub {
    my $val = shift @bind;
    return 'NULL' unless defined $val;
    return $val if $val =~ /^\d+(?:\.\d+)?$/;
    $val =~ s/\\/\\\\/g;
    $val =~ s/\n/\\n/g;
    $val =~ s/\t/\\t/g;
    return "'$val'";
  };
  $sql =~ s/\?/$next->()/eg;
  return $sql;
}

sub dbh {
  my $db = shift;
  return DBI->connect(
    sprintf( 'DBI:mysql:database=%s;host=%s', $db, HOST ),
    USER, PASS, { RaiseError => 1 } );
}

# vim:ts=2:sw=2:sts=2:et:ft=perl


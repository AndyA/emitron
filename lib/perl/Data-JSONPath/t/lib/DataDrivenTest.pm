package DataDrivenTest;

use strict;
use warnings;

use JSON;
use Path::Class;
use Storable qw( dclone );
use Test::Differences;

use base qw( Exporter );

our @EXPORT = qw( ddt );

=head1 NAME

DataDrivenTest - Data driven testing

=cut

sub ddt {
  my ( $name, $url, $cb, %opt ) = @_;
  my ( $fn, $frag ) = ( $url =~ /^(.*)#(.*)$/ ? ( $1, $2 ) : ( $url ) );

  my $td = decode_json file( $fn )->slurp;
  $td = $td->{$frag} if defined $frag;

  if ( $opt{readOnly} ) {
    my $ocb = $cb;
    $cb = sub {
      my $tc  = shift;
      my $cln = dclone( $tc );
      $ocb->( $cln );
      eq_or_diff $cln, $tc, "data unchanged";
    };
  }

  for my $tc ( @$td ) {
    next if $tc->{disabled};
    $cb->( $tc );
  }
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

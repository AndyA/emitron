#!perl

use strict;
use warnings;
use Test::More tests => 23;

use Emitron::Model;
use Data::Dumper;
use File::Temp;
use Scalar::Util qw( refaddr );

{
  my $dir = File::Temp->newdir;
  my $model = Emitron::Model->new( root => $dir );
  isa_ok $model, 'Emitron::Model';
  my $model2 = $model->init;
  my $model3 = $model->init;
  is refaddr( $model ), refaddr( $model2 ), 'init returns model';
  is refaddr( $model ), refaddr( $model3 ), 'second init returns model';
}

with_model(
  sub {
    my ( $model, $dir ) = @_;
    my @rmap = ();
    for my $rev ( 1 .. 10 ) {
      my $rec = { r => $rev };
      my $ver = $model->commit( $rec );
      push @rmap, [ $ver, $rec ];
    }
    for my $rm ( @rmap ) {
      my $rec = $model->checkout( $rm->[0] );
      is_deeply $rec, $rm->[1], "r$rm->[0]";
    }
  }
);

with_model(
  sub {
    my ( $model, $dir ) = @_;
    my $r1 = $model->commit( {} );
    ok defined $r1, "commit 1, no expect";
    my $r2 = $model->commit( { foo => 1 } );
    ok defined $r2, "commit 2, no expect";
    ok !defined $model->commit( { bar => 1 }, $r1 ),
     "commit 3, expect failure";
    ok defined $model->commit( { bar => 1 }, $r2 ),
     "commit 4, expect success";
  }
);

with_model(
  sub {
    my ( $model, $dir ) = @_;
    $model->commit( { r => $_ } ) for 1 .. $model->prune + 10;
    ok $model->revision > $model->prune, 'sane revision';
    ok !
     defined $model->checkout( $model->revision - $model->prune - 1 ),
     'pruned';
    ok defined $model->checkout( $model->revision - $model->prune ),
     'not pruned';
  }
);

with_model(
  sub {
    my ( $model, $dir ) = @_;
    my $fail = 0;
    my $nrev = $model->transaction(
      sub {
        my ( $data, $rev ) = @_;
        # Do another commit to force the transaction to fail
        $model->commit( { fail => $fail++ } ) if $fail < 3;
        return { rev => $fail };
      }
    );
    is $fail, 3, 'failed 3 times';
    ok defined $nrev, 'nrev valid';
    is_deeply $model->checkout( $nrev ), { rev => $fail }, "commit OK";
  }
);

sub with_model {
  my $cb    = shift;
  my $dir   = File::Temp->newdir;
  my $model = Emitron::Model->new( root => $dir, prune => 50 );
  $model->init;
  $cb->( $model, $dir );
}

# vim:ts=2:sw=2:et:ft=perl

#!perl

use strict;
use warnings;

use Test::More tests => 6;

use Data::Dumper;
use Data::JSONPatch qw( json_patch );
use File::Temp;
use POSIX qw( _exit );
use Scalar::Util qw( refaddr );
use Time::HiRes qw( sleep );

use Emitron::Model::Watched;

{
  my $dir = File::Temp->newdir;
  my $model = Emitron::Model::Watched->new( root => $dir );
  isa_ok $model, 'Emitron::Model';
  isa_ok $model, 'Emitron::Model::Watched';
  my $model2 = $model->init;
  my $model3 = $model->init;
  is refaddr($model), refaddr($model2), 'init returns model';
  is refaddr($model), refaddr($model3), 'second init returns model';
}

forked_test(
  sub {
    my ( $model, $rev, $timeout ) = @_;
    return $model->wait( $rev, $timeout );
  }
);

{
  my $sel;
  forked_test(
    sub {
      my ( $model, $rev, $timeout ) = @_;
      $sel ||= IO::Select->new( $model->fileno );
      1 until $sel->can_read;
      return $model->poll;
    }
  );
}

sub forked_test {
  my $cb    = shift;
  my $dir   = File::Temp->newdir;
  my $model = Emitron::Model::Watched->new( root => $dir, prune => 50 );

  my $pid = fork;
  defined $pid or die "Fork failed: $!";
  unless ($pid) {
    # child
    sleep 1;
    $model->init;

    for my $i ( 1 .. 5 ) {
      $model->transaction(
        sub {
          my ( $data, $rev ) = @_;
          my $k = "rev$i";
          $data->{$k} = $k;
          return $data;
        }
      );
      sleep 0.25;
    }

    $model->transaction(
      sub {
        my ( $data, $rev ) = @_;
        $data->{done} = 1;
        return $data;
      }
    );

    _exit(0);
  }

  my $rev  = 1;
  my $data = {};

  until ( $data->{done} ) {
    my $nrev = $cb->( $model, $rev, 10000 );
    if ( defined $nrev && $nrev ne $rev ) {
      my $patch = $model->diff( $rev, $nrev );
      json_patch( $data, $patch );
      $rev = $nrev;
    }
  }

  wait;

  my $want = {
    rev1 => 'rev1',
    rev2 => 'rev2',
    rev3 => 'rev3',
    rev4 => 'rev4',
    rev5 => 'rev5',
    done => 1,
  };

  is_deeply $data, $want, "data patched";
}

sub with_model {
  my $cb    = shift;
  my $dir   = File::Temp->newdir;
  my $model = Emitron::Model::Watched->new( root => $dir, prune => 50 );
  $model->init;
  $cb->( $model, $dir );
}

# vim:ts=2:sw=2:et:ft=perl


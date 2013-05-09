#!perl

use strict;
use warnings;

use File::Temp;
use Path::Class;
use Time::HiRes qw( sleep time );

use Test::More;

use Lintilla::Util qw( :all );

{
  # wait_for_file
  my $td = File::Temp->newdir;

  {
    my $tf = file( $td, 'test' );

    my $pid = fork;
    defined $pid or die "Can't fork: $!";
    unless ($pid) {
      sleep 0.5;
      touch($tf);
      exit;
    }

    my $now = time;
    my $got = wait_for_file( $tf, 2 );
    ok -e $tf, 'file exists';
    is $got, $tf, 'file created';
    ok time - $now > 0.4, 'time passed';
    is wait, $pid, 'child exited';
  }

  {
    my $tf = file( $td, 'test2' );

    my $now = time;
    my $got = wait_for_file( $tf, 1 );
    ok !-e $tf, 'file does not exist';
    is $got, undef, 'file not created';
    ok time - $now > 0.9, 'time passed';
  }

}

done_testing();

sub touch { file($_)->openw->close for @_ }

# vim:ts=2:sw=2:et:ft=perl


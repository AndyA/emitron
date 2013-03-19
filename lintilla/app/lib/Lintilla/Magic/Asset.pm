package Lintilla::Magic::Asset;

use Moose;

use Fcntl qw( :flock );
use Lintilla::Util qw( wait_for_file );
use Path::Class;

=head1 NAME

Lintilla::Magic::Asset - A dynamic, cached asset

=cut

has filename => ( is => 'ro', required => 1 );
has provider => ( is => 'ro', required => 1 );

has timeout => ( isa => 'Maybe[Num]', is => 'ro', default => 20 );

sub get {
  my $self = shift;
  my $fn   = $self->filename;
  unless ( -e $fn ) {
    my $lockf = "$fn.LOCK";
    file($lockf)->parent->mkpath;
    open my $lh, '>>', $lockf or die "Can't write $lockf: $!\n";
    if ( flock( $lh, LOCK_EX ) ) {
      $self->provider->create;    # make the image
      flock( $lh, LOCK_UN ) or die "Can't unlock $lockf: $!\n";
      close $lh;
      unlink $lockf;
    }
    else {
      # Can't get the lock - so wait for the file
      my $got = wait_for_file( $fn, $self->timeout );
      defined $got or die "Gave up waiting for $fn: $!\n";
    }
  }
  return $fn;
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

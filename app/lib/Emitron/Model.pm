package Emitron::Model;

use strict;
use warnings;

use Carp qw( croak );
use Path::Class;
use Storable;

use accessors::ro qw( root );

=head1 NAME

Emitron::Model - versioned model

=cut

sub new {
  my $class = shift;
  return bless {@_}, $class;
}

sub _obj_name { file( shift->root, @_ ) }

sub _index { shift->_obj_name( 'index' ) }

sub _stash { shift->_obj_name( "r$_[0]" ) }

sub init {
  my $self = shift;
  my $idx  = $self->_index;
  return if -f $idx;
  dir( $self->root )->mkpath;
  print { $idx->openw } "0\n";
  $self->commit( {} );
}

sub _with_write_lock {
  my ( $self, $cb ) = @_;
  my $idx = $self->_index;
  open my $fh, '+<', $idx or croak "Can't write $idx: $!\n";
  flock $fh, 2 or croak "Can't lock $idx: $!\n";    # Exclusive
  my $rc = eval { $cb->( $fh ) };
  my $err = $@;
  close $fh;
  croak $err if $err;
  return $rc;
}

sub gc {
  my $self = shift;
}

sub commit {
  my ( $self, $data ) = @_;
  my $rev;
  $self->_with_write_lock(
    sub {
      my $fh = shift;
      chomp( $rev = <$fh> );
      $rev ||= 0;
      my $stash = $self->_stash( ++$rev );
      store $data, $stash or croak "Failed to write $stash: $!";
      seek $fh, 0, 0;
      print $fh "$rev\n";
    }
  );
  return $rev;
}

sub checkout {
  my ( $self, $rev ) = @_;
  my $now = $self->revision;
  return if $rev <= 0 || $rev > $now;
  my $stash = $self->_stash( $rev );
  return unless -f $stash;
  return retrieve $stash or croak "Failed to read $stash: $!";
}

sub revision {
  my $self = shift;
  my $idx  = $self->_index;
  open my $fh, '<', $idx or croak "Can't read $idx: $!\n";
  flock $fh, 1 or croak "Can't lock $idx: $!\n";    # Shared
  chomp( my $rev = <$fh> );
  return $rev;
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

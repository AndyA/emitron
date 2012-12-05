package Emitron::Model::Watched;

use Moose;

use Linux::Inotify2;
use Path::Class;
use IO::Select;
use Time::HiRes qw( time );

extends qw( Emitron::Model::Diff );

=head1 NAME

Emitron::Model::Watched - A model with an associated global event

=cut

sub _evfile { shift->_obj_name( 'event' ) }

sub _signal {
  my ( $self, $rev ) = @_;
  my $evf = $self->_evfile;
  my $tmp = "$evf.tmp";
  {
    open my $fh, '>', $tmp or die "Can't write $tmp: $!";
    print $fh "$rev\n";
  }
  rename $tmp, $evf or die "Can't rename $tmp as $evf: $!\n";
}

sub _inotify {
  my $self = shift;
  return $self->{_inotify} ||= Linux::Inotify2->new;
}

sub fileno {
  my $self = shift;
  $self->_install_watch;
  return $self->_inotify->fileno;
}

sub _make_watch {
  my $self = shift;
  my $evf  = $self->_evfile;
  my $dir  = file( $evf )->parent;

  $self->{_watch}->cancel if $self->{_watch};

  if ( -f $evf ) {
    $self->{_watch} = $self->_inotify->watch(
      $evf,
      IN_MODIFY | IN_DELETE_SELF,
      sub {
        my $ev = shift;
        $self->_make_watch;
      }
    );
    return;
  }

  $self->{_watch} = $self->_inotify->watch(
    "$dir",
    IN_CREATE | IN_MOVED_TO,
    sub {
      my $ev = shift;
      if ( $ev->fullname eq $self->_evfile ) {
        $self->_make_watch;
      }
    }
  );
}

sub _install_watch {
  my $self = shift;
  $self->_make_watch unless exists $self->{_watch};
}

override commit => sub {
  my $self = shift;
  my $rev  = super();
  $self->_signal( $rev ) if defined $rev;
  return $rev;
};

sub _read_ev {
  my $self = shift;
  open my $fh, '<', $self->_evfile or return;
  chomp( my $sn = <$fh> );
  return $sn;
}

sub _drain {
  my $self = shift;
  my $in   = $self->_inotify;
  $in->blocking( 0 );
  $in->poll;
  $in->blocking( 1 );
}

sub poll {
  my $self = shift;
  $self->_drain;
  return $self->_read_ev;
}

sub wait {
  my ( $self, $serial, $timeout ) = @_;

  my $deadline = time + $timeout;

  $self->_drain;
  my $sel = IO::Select->new( $self->fileno );

  while () {
    my $now = time;
    last if $now >= $deadline;

    my $nsn = $self->_read_ev;
    return $nsn if defined $nsn && $nsn ne $serial;

    $self->_inotify->poll
     if $sel->can_read( $deadline - $now );
  }

  return $serial;
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

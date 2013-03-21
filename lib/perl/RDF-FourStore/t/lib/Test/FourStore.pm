package Test::FourStore;

use Moose;

use Path::Class;
use Time::HiRes qw( sleep time );

=head1 NAME

Test::FourStore - Temporary 4store databases.

=cut

has hack4s => (
  is       => 'ro',
  isa      => 'Str',
  default  => 'tools/hack4s.sh',
  required => 1
);

has bin4s => (
  is       => 'ro',
  isa      => 'Str',
  default  => 'bin4s',
  required => 1
);

has tmpdir => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  builder => '_hack4s'
);

has _next => ( is => 'rw', isa => 'Int', default => 1 );

sub _hack4s {
  my $self = shift;
  my $h4s  = $self->hack4s;
  chomp( my $tmp = qx{sh $h4s} );
  return $tmp;
}

sub _which {
  my ( $self, $name ) = @_;
  return '' . file( $self->bin4s, $name );
}

sub clear {
  my $self = shift;
  $_->rmtree for dir( $self->tmpdir )->children;
}

sub make_db {
  my $self = shift;
  $self->_next( ( my $next = $self->_next ) + 1 );
  my $db = sprintf 't%05d', $next;
  system $self->_which('4s-backend-setup'), $db
   and die "4s-backend-setup failed: $?";
  return $db;
}

sub _foex {
  my ( $self, @cmd ) = @_;
  my $pid = fork;
  defined $pid or die "Fork failed: $!";
  return $pid if $pid;
  exec @cmd;
  die "Exec failed: $!";
}

sub with_web_service {
  my ( $self, $port, $db, $cb ) = @_;

  my @pid = ();
  push @pid, $self->_foex( $self->_which('4s-backend'), '-D', $db );
  push @pid,
   $self->_foex( $self->_which('4s-httpd'), '-D', -p => $port, $db );

  print STDERR "# pids: ", join( ', ', @pid ), "\n";

  $cb->("http://localhost:$port");

  kill 2, @pid;

  waitpid $_, 0 for @pid;
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

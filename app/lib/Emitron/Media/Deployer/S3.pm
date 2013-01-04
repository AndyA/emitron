package Emitron::Media::Deployer::S3;

use Moose;

use Carp qw( croak );
use Config::Tiny;
use DateTime;
use Emitron::App;
use Emitron::Logger;
use Harmless::M3U8;
use Linux::Inotify2;
use Net::Amazon::S3::Client;
use Net::Amazon::S3;
use Path::Class;

extends 'Emitron::Media::Base';
with 'Emitron::Media::Roles::Forker';

=head1 NAME

Emitron::Media::Deployer::S3 - S3 Deployer

=cut

has config => (
  isa      => 'HashRef',
  is       => 'ro',
  required => 1,
);

has ['pid', 'manifest'] => (
  isa      => 'Str',
  is       => 'ro',
  required => 1,
);

has path => (
  isa     => 'Str',
  is      => 'ro',
  lazy    => 1,
  default => sub { shift->pid },
);

has _inotify => (
  isa     => 'Linux::Inotify2',
  is      => 'ro',
  lazy    => 1,
  default => sub {
    Linux::Inotify2->new
     or croak "Can't create inotify: $!";
  }
);

has _s3 => (
  isa     => 'Net::Amazon::S3',
  is      => 'ro',
  lazy    => 1,
  builder => '_mk_s3'
);

has _s3c => (
  isa     => 'Net::Amazon::S3::Client',
  is      => 'ro',
  lazy    => 1,
  default => sub { Net::Amazon::S3::Client->new( s3 => shift->_s3 ) },
);

has _bucket => (
  isa     => 'Net::Amazon::S3::Client::Bucket',
  is      => 'ro',
  lazy    => 1,
  default => sub {
    my $self = shift;
    return $self->_s3c->bucket( name => $self->_bucket_name );
  },
);

sub _uniq {
  my %seen = ();
  grep { !$seen{$_}++ } @_;
}

sub _bucket_name { shift->config->{bucket} }
sub _config      { shift->config->{config} }
sub _profile     { shift->config->{profile} }

sub _mk_s3 {
  my $self = shift;
  my $cfg  = Config::Tiny->read( $self->_config )
   or croak Config::Tiny->errstr;
  my $pro = $cfg->{ $self->_profile }
   or croak "Profile ", $self->_profile, " not defined";
  debug "Creating S3 connection";
  return Net::Amazon::S3->new(
    { aws_access_key_id     => $pro->{access_key},
      aws_secret_access_key => $pro->{secret_key},
      retry                 => 1,
    }
  );
}

sub _object {
  my ( $self, $key, $mime, $ttl ) = @_;

  my $now = DateTime->now;

  my @args = (
    key           => $key,
    content_type  => $mime,
    acl_short     => 'public-read',
    last_modified => $now,
  );

  if ( defined $ttl ) {
    my $exp = $now->clone;
    $exp->add( seconds => $ttl );
    push @args, ( expires => $exp, );
  }

  return $self->_bucket->object(@args);
}

sub _deploy {
  my ( $self, $file, $key, $mime, $ttl ) = @_;
  debug "Deploying $file as $key ($mime)";
  my $obj = $self->_object( $key, $mime, $ttl );
  $obj->put_filename($file);
}

sub _deploy_m3u8 {
  my ( $self, $file, $key, $ttl ) = @_;
  $self->_deploy( $file, $key, 'application/x-mpegURL', $ttl );
}

sub _deploy_frags {
  my ( $self, $mf, $key ) = @_;
  my $mfd      = file($mf)->parent;
  my $m3u8     = Harmless::M3U8->new->read($mf);
  my $duration = $m3u8->meta->{EXT_X_TARGETDURATION} || 4;
  my @seg      = map { $_->{uri} } map { @$_ } @{ $m3u8->seg };
  my @todo     = ();
  while (@seg) {
    my $seg = pop @seg;
    my $obj = $self->_object( $seg, 'video/MP2T' );
    last if $obj->exists;
    unshift @todo, [$seg, $obj];
  }
  for my $todo (@todo) {
    my ( $seg, $obj ) = @$todo;
    debug "Deploying segment $seg";
    $obj->put_filename( file( $mfd, $seg ) );
  }
  $self->_deploy_m3u8( $mf, $key, $duration / 2 );
}

sub _find_dynamic_manifests {
  my $self = shift;
  my $mf   = $self->manifest;
  # TODO: possible race here - the manifest might not yet exist.
  # Ideally we should have some kind of inotify based callback
  # widget to allow us to wait for files generically. In practice
  # in this case the model propagation delay means that the race
  # risk is fairly low.
  my $m3u8 = Harmless::M3U8->new->read($mf);
  my $vpl  = $m3u8->vpl;
  return $mf unless @$vpl;
  my $mfd = file($mf)->parent;
  return map { file( $mfd, $_->{uri} )->stringify } @$vpl;
}

sub _mk_inotify {
  my ( $self, @mf ) = @_;
  my $mfd  = file( $self->manifest )->parent;
  my %mine = map { $_ => [] } @mf;
  my @mfd  = _uniq( map { file($_)->parent } @mf );
  for my $mfd (@mfd) {
    debug "Adding watch for $mfd";
    $self->_inotify->watch(
      $mfd,
      IN_MOVED_TO | IN_CREATE,
      sub {
        my $evt = shift;
        my $src = $evt->fullname;
        if ( $mine{$src} ) {
          my $key = $self->_key( file($src)->relative($mfd) );
          $self->_deploy_frags( $src, $key );
        }
      }
    );
  }
}

sub _key {
  my ( $self, @p ) = @_;
  return join '/', $self->path, @p;
}

sub _manifest_key {
  my $self = shift;
  my $mf = join '.', $self->pid, 'm3u8';
  return $self->_key($mf);
}

sub start {
  my $self = shift;
  $self->fork(
    sub {
      my @mf = $self->_find_dynamic_manifests;
      debug "Manifests: ", join ', ', @mf;
      $self->_mk_inotify(@mf);
      $self->_deploy_m3u8( $self->manifest, $self->_manifest_key, 60 );
      debug "Polling...";
      1 while $self->_inotify->poll;
    }
  );
}

sub stop {
  my $self = shift;
  $self->kill_all;
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

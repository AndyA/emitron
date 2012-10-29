package Emitron::EvoStream;

use strict;
use warnings;

use Data::Dumper;
use JSON::XS;
use LWP::UserAgent;
use MIME::Base64;

use Emitron::EvoStream::JSON qw( detox_json );

use accessors::ro qw( host port );

BEGIN {
  my %API = (
    add_stream_alias                 => 'addStreamAlias',
    create_hLSStream                 => 'createHLSStream',
    create_service                   => 'createService',
    enable_service                   => 'enableService',
    flush_stream_aliases             => 'flushStreamAliases',
    get_bandwidth                    => 'getBandwidth',
    get_connection_info              => 'getConnectionInfo',
    get_connections_count            => 'getConnectionsCount',
    get_connections_count_limit      => 'getConnectionsCountLimit',
    get_extended_connection_counters => 'getExtendedConnectionCounters',
    get_stream_info                  => 'getStreamInfo',
    get_streams_count                => 'getStreamsCount',
    help                             => 'help',
    list_connections                 => 'listConnections',
    list_connections_ids             => 'listConnectionsIds',
    list_pull_push_config            => 'listPullPushConfig',
    list_services                    => 'listServices',
    list_stream_aliases              => 'listStreamAliases',
    list_streams                     => 'listStreams',
    list_streams_ids                 => 'listStreamsIds',
    pull_stream                      => 'pullStream',
    push_stream                      => 'pushStream',
    quit                             => 'quit',
    record                           => 'record',
    remove_pull_push_config          => 'removePullPushConfig',
    remove_stream_alias              => 'removeStreamAlias',
    reset_max_fd_counters            => 'resetMaxFdCounters',
    reset_total_fd_counters          => 'resetTotalFdCounters',
    set_authentication               => 'setAuthentication',
    set_bandwidth_limit              => 'SetBandwidthLimit',
    set_connections_count_limit      => 'setConnectionsCountLimit',
    set_log_level                    => 'setLogLevel',
    shutdown_server                  => 'shutdownServer',
    shutdown_service                 => 'shutdownService',
    shutdown_stream                  => 'shutdownStream',
    version                          => 'version',
  );
  while ( my ( $method, $api ) = each %API ) {
    no strict 'refs';
    *$method = sub { shift->api( $api, @_ ) };
    *$api = *$method unless $api eq $method;
  }
}

=head1 NAME

Emitron::EvoStream - EvoStream Media Server API

=cut

sub new {
  my ( $class, %args ) = @_;
  return bless { %args, host => 'localhost', port => '7777' }, $class;
}

sub ua {
  my $self = shift;
  return $self->{ua} ||= LWP::UserAgent->new;
}

sub api {
  my ( $self, $function, %args ) = @_;
  my $uri
   = 'http://' . $self->host . ':' . $self->port . '/' . $function;
  if ( keys %args ) {
    my $args = join ' ', map { "$_=$args{$_}" } sort keys %args;
    $uri .= '?params=' . encode_base64( $args, '' );
  }
  my $resp = $self->ua->get( $uri );
  die $resp->status_line if $resp->is_error;
  return detox_json decode_json $resp->content;
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl

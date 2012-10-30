package Emitron;
use Dancer ':syntax';
use IPC::GlobalEvent qw( eventsignal eventwait );

use constant SEMFILE => '/tmp/emitron.event';

# Hack
eventsignal( SEMFILE, 1 );

our $VERSION = '0.1';

get '/' => sub {
  template 'index';
};

get '/api/ev/:serial?' => sub {
  my $sn = param( 'serial' ) || 0;
  my $next = eventwait( SEMFILE, $sn, 5000 );
  return { name => 'keepalive' } if $next == $sn;    # timeout
  return {
    name   => 'test',
    data   => { sequence => $next },
    serial => $next
  };
};

true;

package Emitron;
use Dancer ':syntax';
use Emitron::Model::Watched;

use constant QUEUE => '/tmp/emitron.queue';
use constant MODEL => '/tmp/emitron.model';

our $VERSION = '0.1';

my $model = Emitron::Model::Watched->new( root => MODEL )->init;
my $queue = Emitron::Model::Watched->new( root => QUEUE )->init;

get '/' => sub {
  template 'index';
};

sub model_message {
  my $sn  = shift;
  my $now = $model->revision;
  return if $sn == $now;
  my $diff = $model->diff( $sn, $now );
  return { name => 'model-patch', data => $diff, serial => $now }
   if $diff;
  return {
    name   => 'model',
    data   => $model->checkout($now),
    serial => $now
  };
}

get '/api/ping' => sub {
  my $msg = { type => 'ping' };
  $queue->commit($msg);
  return $msg;
};

get '/api/ev/:serial?' => sub {
  my $sn = param('serial') || 0;
  { my $msg = model_message($sn); return $msg if $msg }
  my $next = $model->wait( $sn, 10 );
  { my $msg = model_message($sn); return $msg if $msg }
  return { name => 'keepalive' };
};

true;

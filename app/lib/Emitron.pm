package Emitron;
use Dancer ':syntax';
use Emitron::Model::Watched;

use constant SEMFILE => '/tmp/emitron.event';
use constant MODEL   => '/tmp/emitron.model';

our $VERSION = '0.1';

my $model = Emitron::Model::Watched->new( root => MODEL );
$model->init;

get '/' => sub {
  template 'index';
};

sub _model_message {
  my $sn  = shift;
  my $now = $model->revision;
  return if $sn == $now;
  my $diff = $model->diff( $sn, $now );
  return { name => 'model-patch', data => $diff, serial => $now }
   if $diff;
  return {
    name   => 'model',
    data   => $model->checkout( $now ),
    serial => $now
  };
}

sub model_message {
  my $sn  = shift;
  my $msg = _model_message( $sn );
  debug("Sending ", $msg);
  return $msg;
}

get '/api/ev/:serial?' => sub {
  my $sn = param( 'serial' ) || 0;
  { my $msg = model_message( $sn ); return $msg if $msg }
  my $next = $model->wait( $sn, 10000 );
  { my $msg = model_message( $sn ); return $msg if $msg }
  return { name => 'keepalive' };
};

true;

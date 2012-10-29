package Emitron;
use Dancer ':syntax';

our $VERSION = '0.1';

get '/' => sub {
  template 'index';
};

get '/api/ev' => sub {
  sleep 5;
  return { name => 'test', data => { foo => 1 } };
};

true;

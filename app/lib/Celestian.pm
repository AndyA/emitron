package Emitron;
use Dancer ':syntax';

our $VERSION = '0.1';

get '/' => sub {
    template 'index';
};

get '/api/ev' => sub {

};

true;

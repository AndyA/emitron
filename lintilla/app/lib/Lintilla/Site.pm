package Lintilla::Site;
use Dancer ':syntax';

our $VERSION = '0.1';

get '/' => sub {
  template 'index';
};

get '/app/helper' => sub {
  content_type 'text/plain';
  return "Hello, World!";
};

get '/app/404' => sub {
  template 'index';
};

true;

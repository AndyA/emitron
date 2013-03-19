package Lintilla::Site;
use Dancer ':syntax';

use Lintilla::Magic::Asset;

our $VERSION = '0.1';

get '/' => sub {
  template 'index';
};

get '/asset/**/var/*/*.jpg' => sub {
  my ( $path, $recipe, $id ) = splat;
  return {
    path   => join( '/', @$path ),
    id     => $id,
    recipe => $recipe,
  };
};

get '/app/helper' => sub {
  content_type 'text/plain';
  return "Hello, World!";
};

true;

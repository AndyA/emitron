package Lintilla::Site;
use Dancer ':syntax';

use Lintilla::Image::Scaler;
use Lintilla::Magic::Asset;
use Path::Class;

our $VERSION = '0.1';

use constant DOCROOT => '/opt/newstream/lintilla/app/public';    # FIXME

get '/' => sub {
  template 'index';
};

# TODO move this into a config file.
# TODO it'd be nice to be able to have, say, thumb80 depend
# on small200 to avoid loading the original repeatedly.
my %RECIPE = (
  thumb80 => {
    width  => 80,
    height => 80
  },
  small200 => {
    width  => 200,
    height => 200
  }
);

get '/asset/**/var/*/*.jpg' => sub {
  my ( $path, $recipe, $id ) = splat;

  die "Bad recipe" unless $recipe =~ /^\w+$/;
  my $spec = $RECIPE{$recipe};
  die "Unknown recipe $recipe" unless defined $spec;

  my $dir = join '/', @$path;

  my $in_file = file( DOCROOT, 'asset', $dir, "$id.jpg" );
  my $out_file = file( DOCROOT, 'asset', $dir, 'var', $recipe, "$id.jpg" );

  my $sc = Lintilla::Image::Scaler->new(
    in_file  => $in_file,
    out_file => $out_file,
    spec     => $spec
  );

  my $magic = Lintilla::Magic::Asset->new(
    filename => $out_file,
    timeout  => 20,
    provider => $sc
  );

  $magic->get;

  my $self = uri_for("/asset/$dir/var/$recipe/$id.jpg");
  debug "self: ", $self;

  return redirect $self;
};

get '/app/helper' => sub {
  content_type 'text/plain';
  return "Hello, World!";
};

true;

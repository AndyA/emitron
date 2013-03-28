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
my %RECIPE = (
  display => {
    width  => 1024,
    height => 576,
  },
  thumb => {
    width  => 80,
    height => 80,
    base   => 'display',
  },
  small => {
    width  => 200,
    height => 200,
    base   => 'display',
  },
  slice => {
    width  => 800,
    height => 150,
    base   => 'display',
  },
);

sub our_uri_for {
  my $uri = request->uri_for( join '/', '', @_ );
  $uri =~ s@/dispatch\.f?cgi/@/@;    # hack
  return $uri;
}

get '/config/recipe' => sub {
  return \%RECIPE;
};

get '/asset/**/var/*/*.jpg' => sub {
  my ( $path, $recipe, $id ) = splat;

  die "Bad recipe" unless $recipe =~ /^\w+$/;
  my $spec = $RECIPE{$recipe};
  die "Unknown recipe $recipe" unless defined $spec;

  my $name = "$id.jpg";

  my @p = ( asset => @$path );
  my @v = ( var   => $recipe );

  my $in_url = our_uri_for( @p,
    ( defined $spec->{base} ? ( var => $spec->{base} ) : () ), $name );

  my $out_file = file( DOCROOT, @p, @v, $name );

  debug "in_url: $in_url";
  debug "out_file: $out_file";

  my $sc = Lintilla::Image::Scaler->new(
    in_url   => $in_url,
    out_file => $out_file,
    spec     => $spec
  );

  my $magic = Lintilla::Magic::Asset->new(
    filename => $out_file,
    timeout  => 20,
    provider => $sc
  );

  $magic->get or die "Can't render";

  my $self = our_uri_for( @p, @v, $name );

  return redirect $self, 307;
};

true;

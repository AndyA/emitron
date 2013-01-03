#!perl

use strict;
use warnings;

use Data::Dumper;
use Test::More;
use Storable qw( freeze );

use ForkPipe::Util::Bag;

ok my $bag = ForkPipe::Util::Bag->new, 'new';
isa_ok $bag, 'ForkPipe::Util::Bag';

my $o1 = { foo => 1 };
my $o2 = { bar => 2 };
my $o3 = { baz => 3 };

$bag->add( $o1, $o2 );

ok $bag->contains($o1), 'contains o1';
ok $bag->contains($o2), 'contains o2';
ok $bag->contains( $o1, $o2 ), 'contains o1, o2';
ok !$bag->contains($o3), "doesn't contain o3";
ok !$bag->contains( $o1, $o2, $o3 ), "doesn't contain all of o1, o2, o3";

$bag->add($o3);
ok $bag->contains( $o1, $o2, $o3 ), "contains all of o1, o2, o3";

$bag->remove($o2);
ok !$bag->contains( $o1, $o2, $o3 ), "doesn't contain all of o1, o2, o3";
ok $bag->contains( $o1, $o3 ), "still contains all of o1, o3";

my @elt = $bag->elements;

is_deeply [normalise(@elt)], [normalise( $o1, $o3 )], 'elements';

done_testing();

sub normalise {
  map { $_->[0] }
   sort { $a->[1] cmp $b->[1] } map { [$_, freeze($_)] } @_;
}

# vim:ts=2:sw=2:et:ft=perl


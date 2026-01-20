use v5.36;
use Test::More;

BEGIN {
    eval { require Moo; 1 } or plan skip_all => q{Moo not installed};
    eval { require MooX::Clone; 1 } or plan skip_all => q{MooX::Clone not installed};
}

require '../monster_army_04.pl';

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, @_ };

my $weapon = Weapon->new(name => '炎の剣', power => 10);
my $dragon1 = Monster->new(
    name    => 'ドラゴン1',
    hp      => 100,
    attack  => 20,
    defense => 15,
    weapon  => $weapon,
);

my $dragon2 = $dragon1->clone;
$dragon2->weapon->power(50);

is $dragon1->weapon->power, 50, 'weapon power shared in shallow copy';
ok $dragon1->weapon == $dragon2->weapon, 'weapon object is shared';

is scalar @warnings, 0, 'no warnings';

done_testing;

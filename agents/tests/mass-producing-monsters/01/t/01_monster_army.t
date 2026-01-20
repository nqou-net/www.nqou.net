use v5.36;
use Test::More;

BEGIN {
    eval { require Moo; 1 } or plan skip_all => q{Moo not installed};
}

require '../monster_army_01.pl';

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, @_ };

my $slime = Monster->new(
    name    => 'スライム',
    hp      => 10,
    attack  => 3,
    defense => 2,
);

is $slime->name, 'スライム', 'name is set';
is $slime->hp, 10, 'hp is set';
is $slime->attack, 3, 'attack is set';
is $slime->defense, 2, 'defense is set';
is $slime->color, '緑', 'default color is 緑';

is scalar @warnings, 0, 'no warnings';

done_testing;

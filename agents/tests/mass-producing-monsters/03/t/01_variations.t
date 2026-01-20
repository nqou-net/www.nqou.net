use v5.36;
use Test::More;

BEGIN {
    eval { require Moo; 1 } or plan skip_all => q{Moo not installed};
    eval { require MooX::Clone; 1 } or plan skip_all => q{MooX::Clone not installed};
}

require '../monster_army_03.pl';

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, @_ };

my $base_slime = Monster->new(
    name    => 'スライム',
    hp      => 10,
    attack  => 3,
    defense => 2,
);

my $red_slime = $base_slime->clone;
$red_slime->color('赤');

is $base_slime->color, '緑', 'base color unchanged';
is $red_slime->color, '赤', 'clone color changed';

my $strong_slime = $base_slime->clone;
$strong_slime->hp(15);
$strong_slime->attack(5);
$strong_slime->defense(3);

is $strong_slime->hp, 15, 'strong slime hp updated';
is $base_slime->hp, 10, 'base slime hp unchanged';

is scalar @warnings, 0, 'no warnings';

done_testing;

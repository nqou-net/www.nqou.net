use v5.36;
use Test::More;

BEGIN {
    eval { require Moo; 1 } or plan skip_all => q{Moo not installed};
}

require '../prototype_06.pl';

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, @_ };

ok Monster->does('Cloneable'), 'Monster does Cloneable role';
ok Weapon->does('Cloneable'), 'Weapon does Cloneable role';

my $weapon = Weapon->new(name => '氷の剣', power => 5);
my $monster = Monster->new(
    name    => 'スライム',
    hp      => 10,
    attack  => 3,
    defense => 2,
    weapon  => $weapon,
);

my $clone = $monster->clone;
$clone->weapon->power(20);

is $monster->weapon->power, 5, 'clone changes do not affect original';
ok $monster->weapon != $clone->weapon, 'weapon objects are distinct';

is scalar @warnings, 0, 'no warnings';

done_testing;

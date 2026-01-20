use v5.36;
use Test::More;

BEGIN {
    eval { require Moo; 1 } or plan skip_all => q{Moo not installed};
    eval { require MooX::Clone; 1 } or plan skip_all => q{MooX::Clone not installed};
}

require '../monster_army_02.pl';

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, @_ };

my $base_slime = Monster->new(
    name    => 'スライム',
    hp      => 10,
    attack  => 3,
    defense => 2,
);

my $clone = $base_slime->clone;

is $clone->name, 'スライム', 'clone keeps name';
$clone->hp(15);
is $base_slime->hp, 10, 'base slime unchanged';

is scalar @warnings, 0, 'no warnings';

done_testing;

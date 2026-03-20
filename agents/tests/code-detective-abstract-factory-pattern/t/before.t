use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use Test::More;

do './agents/tests/code-detective-abstract-factory-pattern/before/lib.pl' or die $@ || $!;

subtest 'Before: Mismatched Product Family' => sub {
    my $gen = WorldGenerator->new;

    # 正常系: 同じバイオームなら揃う
    my $forest = $gen->generate_zone('forest');
    is($forest->{terrain}{name}, '古代樹の森', 'forest zone: terrain OK');
    is($forest->{creature}{name}, 'エルフの弓兵', 'forest zone: creature OK');
    is($forest->{weather}{name}, '精霊の霧', 'forest zone: weather OK');

    # BUG: 遷移ゾーンで異なるファミリーが混在
    my $transition = $gen->generate_transition('forest', 'ocean');
    is($transition->{terrain}{name}, '古代樹の森', 'transition: terrain from forest');
    is($transition->{creature}{name}, 'クラーケン', 'BUG: creature from ocean in forest terrain!');
    is($transition->{weather}{name}, '精霊の霧', 'transition: weather from forest');

    # 火山追加には3メソッドすべてにelsif追加が必要
    eval { $gen->generate_zone('volcano') };
    like($@, qr/Unknown biome/, 'Adding volcano requires modifying 3 methods');
};

done_testing;

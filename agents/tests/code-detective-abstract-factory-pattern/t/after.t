use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use Test::More;

do './agents/tests/code-detective-abstract-factory-pattern/after/lib.pl' or die $@ || $!;

subtest 'After: Abstract Factory Pattern' => sub {
    # 各ファクトリーがファミリーの一貫性を保証
    my $forest_gen = WorldGenerator->new(factory => ForestFactory->new);
    my $forest = $forest_gen->generate;
    is($forest->{terrain}->name, '古代樹の森', 'ForestFactory: terrain');
    is($forest->{creature}->name, 'エルフの弓兵', 'ForestFactory: creature');
    is($forest->{weather}->name, '精霊の霧', 'ForestFactory: weather');

    my $desert_gen = WorldGenerator->new(factory => DesertFactory->new);
    my $desert = $desert_gen->generate;
    is($desert->{terrain}->name, '灼熱の砂漠', 'DesertFactory: terrain');
    is($desert->{creature}->name, 'サンドワーム', 'DesertFactory: creature');

    my $ocean_gen = WorldGenerator->new(factory => OceanFactory->new);
    my $ocean = $ocean_gen->generate;
    is($ocean->{creature}->name, 'クラーケン', 'OceanFactory: creature');

    # ファクトリーベースの生成ではファミリー混在が構造的に不可能
    # ForestFactory を渡したら森の製品しか出てこない
    ok($forest->{terrain}->isa('Terrain'), 'Products are proper objects');
    ok($forest->{creature}->isa('Creature'), 'Creature is proper object');

    # 火山バイオーム追加: 既存コード変更ゼロ
    my $volcano_gen = WorldGenerator->new(factory => VolcanoFactory->new);
    my $volcano = $volcano_gen->generate;
    is($volcano->{terrain}->name, '溶岩の大地', 'VolcanoFactory: terrain');
    is($volcano->{creature}->name, 'サラマンダー', 'VolcanoFactory: creature');
    is($volcano->{weather}->name, '火山灰の雨', 'VolcanoFactory: weather');

    # WorldGenerator はどのファクトリーでも動く
    for my $factory_class (qw(ForestFactory DesertFactory OceanFactory VolcanoFactory)) {
        my $gen = WorldGenerator->new(factory => $factory_class->new);
        my $zone = $gen->generate;
        ok($zone->{terrain}->isa('Terrain'), "$factory_class works with WorldGenerator");
    }
};

done_testing;

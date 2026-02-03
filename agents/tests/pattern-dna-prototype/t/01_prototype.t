#!/usr/bin/env perl
use v5.36;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

subtest 'Before: 毎回DBからロード' => sub {
    require 'before.pl';

    my $factory = Before::EnemyFactory->new;

    # スライムを生成
    my $slime = $factory->create('slime');
    is($slime->name,   'スライム', 'スライムの名前');
    is($slime->max_hp, 30,     'スライムの最大HP');
    is($slime->attack, 5,      'スライムの攻撃力');

    # ゴブリンを生成
    my $goblin = $factory->create('goblin');
    is($goblin->name,   'ゴブリン', 'ゴブリンの名前');
    is($goblin->max_hp, 50,     'ゴブリンの最大HP');

    # ドラゴンを生成
    my $dragon = $factory->create('dragon');
    is($dragon->name,   'ドラゴン', 'ドラゴンの名前');
    is($dragon->max_hp, 500,    'ドラゴンの最大HP');

    # ダメージ処理
    my $damage = $slime->take_damage(10);
    ok($damage > 0,      'ダメージを受けた');
    ok($slime->is_alive, 'まだ生きている');
};

subtest 'After: Prototypeパターンでクローン生成' => sub {
    require 'after.pl';

    my $registry = After::EnemyRegistry->new;

    # プロトタイプを登録
    $registry->register('slime');
    is($registry->load_count, 1, '1回のDBアクセス');

    # クローンを複数生成
    my $slime1 = $registry->create('slime');
    my $slime2 = $registry->create('slime');
    my $slime3 = $registry->create('slime');

    is($registry->load_count, 1, 'まだ1回のDBアクセス（クローンはDBアクセスなし）');

    # 各クローンが独立していることを確認
    is($slime1->name, 'スライム', 'クローン1の名前');
    is($slime2->name, 'スライム', 'クローン2の名前');
    is($slime3->name, 'スライム', 'クローン3の名前');

    # HPが個別に管理されることを確認
    $slime1->take_damage(20);
    ok($slime1->hp < $slime1->max_hp, 'slime1はダメージを受けた');
    is($slime2->hp, $slime2->max_hp, 'slime2はダメージを受けていない');

    # 深いコピーの確認（スキル配列が独立）
    push @{$slime1->skills}, '毒攻撃';
    ok(grep { $_ eq '毒攻撃' } @{$slime1->skills},  'slime1に毒攻撃スキルがある');
    ok(!grep { $_ eq '毒攻撃' } @{$slime2->skills}, 'slime2に毒攻撃スキルがない（深いコピー確認）');
};

subtest 'レジストリの動作確認' => sub {
    my $registry = After::EnemyRegistry->new;

    # 複数種類を登録
    $registry->register('slime');
    $registry->register('goblin');
    $registry->register('dragon');

    is($registry->load_count, 3, '3種類で3回のDBアクセス');

    # 大量生成してもDBアクセスは増えない
    for (1 .. 100) {
        $registry->create('slime');
        $registry->create('goblin');
        $registry->create('dragon');
    }

    is($registry->load_count, 3, '300体生成しても3回のDBアクセス');
};

done_testing;

#!/usr/bin/env perl
# ダメージ計算テスト
use v5.36;
use warnings;
use utf8;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

# テスト用キャラクター設定
my $attacker = {
    attack        => 150,
    magic_attack  => 120,
    defense       => 50,
    magic_defense => 40,
    hp            => 500,
    max_hp        => 500,
    buffs         => {},
};

my $defender = {
    attack        => 80,
    defense       => 60,
    magic_defense => 70,
    hp            => 400,
    max_hp        => 400,
    weakness      => '炎',
    resistance    => '氷',
    debuffs       => {},
};

# Before版のテスト
subtest 'Before版: DamageCalculator::Legacy' => sub {
    require 'damage_calculator_before.pl';

    my $calc = DamageCalculator::Legacy->new(
        attacker => $attacker,
        defender => $defender,
    );

    # 物理ダメージ
    my $phys = $calc->calculate('物理');
    ok($phys > 0, "物理ダメージは正の値: $phys");
    is($phys, 90, "物理ダメージ (150 - 60) = 90");

    # 物理クリティカル
    my $phys_crit = $calc->calculate('物理', critical => 1);
    ok($phys_crit > $phys, "クリティカルは通常より大きい");
    is($phys_crit, 135, "クリティカル (90 * 1.5) = 135");

    # 固定ダメージ
    my $fixed = $calc->calculate('固定', fixed_damage => 200);
    is($fixed, 200, "固定ダメージはそのまま");

    # 割合ダメージ
    my $percent = $calc->calculate('割合', percent => 10);
    is($percent, 40, "割合ダメージ (400 * 10%) = 40");
};

# After版のテスト
subtest 'After版: Strategy パターン' => sub {

    # 新しいプロセスで読み込み
    require 'damage_calculator_after.pl';

    my $calc = DamageCalculator->new(
        attacker => $attacker,
        defender => $defender,
    );

    # Strategy登録
    $calc->register_strategy(PhysicalDamageStrategy->new);
    $calc->register_strategy(MagicDamageStrategy->new);
    $calc->register_strategy(FixedDamageStrategy->new);
    $calc->register_strategy(PercentDamageStrategy->new);
    $calc->register_strategy(PenetrationDamageStrategy->new);
    $calc->register_strategy(MultiHitDamageStrategy->new);

    # 物理ダメージ
    my $phys = $calc->calculate('物理');
    ok($phys > 0, "物理ダメージは正の値: $phys");
    is($phys, 90, "物理ダメージ (150 - 60) = 90");

    # 物理クリティカル
    my $phys_crit = $calc->calculate('物理', critical => 1);
    ok($phys_crit > $phys, "クリティカルは通常より大きい");
    is($phys_crit, 135, "クリティカル (90 * 1.5) = 135");

    # 固定ダメージ
    my $fixed = $calc->calculate('固定', fixed_damage => 200);
    is($fixed, 200, "固定ダメージはそのまま");

    # 割合ダメージ
    my $percent = $calc->calculate('割合', percent => 10);
    is($percent, 40, "割合ダメージ (400 * 10%) = 40");

    # 貫通ダメージ（50%貫通）
    my $pene = $calc->calculate('貫通', penetration => 0.5);
    ok($pene > 90, "貫通は通常物理より大きい: $pene");
    is($pene, 120, "貫通 (150 - 30) = 120");

    # 連撃ダメージ（3回）
    my $multi = $calc->calculate('連撃', hits => 3);
    ok($multi > 0, "連撃ダメージは正の値: $multi");
    is($multi, 135, "連撃 ((150-60)/2 * 3) = 135");
};

# Factory テスト
subtest 'DamageStrategyFactory' => sub {
    my @types = DamageStrategyFactory->available_types;
    ok(scalar(@types) >= 6, "6種類以上の攻撃タイプが登録: " . scalar(@types));

    for my $type (@types) {
        my $strategy = DamageStrategyFactory->create($type);
        isa_ok($strategy, 'DamageStrategy', "$type Strategy");
        is($strategy->name, $type, "$type Strategy has correct name");
    }
};

# Before/After 一致テスト
subtest 'Before/After 互換性' => sub {
    my $legacy = DamageCalculator::Legacy->new(
        attacker => $attacker,
        defender => $defender,
    );

    my $modern = DamageCalculator->new(
        attacker => $attacker,
        defender => $defender,
    );
    for my $strategy (DamageStrategyFactory->create_all) {
        $modern->register_strategy($strategy);
    }

    # 同じ入力に対して同じ結果
    is($legacy->calculate('物理'), $modern->calculate('物理'), '物理ダメージが一致');

    is($legacy->calculate('固定', fixed_damage => 100), $modern->calculate('固定', fixed_damage => 100), '固定ダメージが一致');

    is($legacy->calculate('割合', percent => 15, cap => 9999), $modern->calculate('割合', percent => 15, cap => 9999), '割合ダメージが一致');
};

done_testing;

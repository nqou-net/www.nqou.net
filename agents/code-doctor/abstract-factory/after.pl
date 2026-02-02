#!/usr/bin/env perl
# ==========================================================
# After: Abstract Factory 適用後
# 難易度切り替えが1箇所で完結、製品ファミリーの整合性保証
# ==========================================================
use v5.40;

# =====================
# 製品ロール（インターフェース）
# =====================

package Enemy::Role {
    use Moo::Role;

    has name => (is => 'ro', required => 1);
    has hp   => (is => 'ro', required => 1);

    requires 'attack_power';
}

package Weapon::Role {
    use Moo::Role;

    has name => (is => 'ro', required => 1);
    has atk  => (is => 'ro', required => 1);
}

package Item::Role {
    use Moo::Role;

    has name   => (is => 'ro', required => 1);
    has effect => (is => 'ro', required => 1);
}

# =====================
# Easy 製品ファミリー
# =====================

package Easy::Enemy {
    use Moo;
    with 'Enemy::Role';
    has '+name' => (default => 'スライム');
    has '+hp'   => (default => 30);
    sub attack_power {5}
}

package Easy::Weapon {
    use Moo;
    with 'Weapon::Role';
    has '+name' => (default => '木の剣');
    has '+atk'  => (default => 10);
}

package Easy::Item {
    use Moo;
    with 'Item::Role';
    has '+name'   => (default => '薬草');
    has '+effect' => (default => '20回復');
}

# =====================
# Normal 製品ファミリー
# =====================

package Normal::Enemy {
    use Moo;
    with 'Enemy::Role';
    has '+name' => (default => 'ゴブリン');
    has '+hp'   => (default => 80);
    sub attack_power {15}
}

package Normal::Weapon {
    use Moo;
    with 'Weapon::Role';
    has '+name' => (default => '鉄の剣');
    has '+atk'  => (default => 30);
}

package Normal::Item {
    use Moo;
    with 'Item::Role';
    has '+name'   => (default => 'ポーション');
    has '+effect' => (default => '50回復');
}

# =====================
# Hard 製品ファミリー
# =====================

package Hard::Enemy {
    use Moo;
    with 'Enemy::Role';
    has '+name' => (default => 'ドラゴン');
    has '+hp'   => (default => 200);
    sub attack_power {40}
}

package Hard::Weapon {
    use Moo;
    with 'Weapon::Role';
    has '+name' => (default => '炎の刀');
    has '+atk'  => (default => 80);
}

package Hard::Item {
    use Moo;
    with 'Item::Role';
    has '+name'   => (default => 'エリクサー');
    has '+effect' => (default => '全回復');
}

# =====================
# Abstract Factory ロール
# =====================

package DifficultyFactory::Role {
    use Moo::Role;

    # 製品ファミリーを一括で生成するインターフェース
    requires qw(create_enemy create_weapon create_item);

    # 難易度名（デバッグ用）
    requires 'difficulty_name';
}

# =====================
# 具象 Factory
# =====================

package EasyFactory {
    use Moo;
    with 'DifficultyFactory::Role';

    sub difficulty_name {'EASY'}

    # Easy製品ファミリーのみを生成 → 不整合が構造上不可能！
    sub create_enemy  { Easy::Enemy->new() }
    sub create_weapon { Easy::Weapon->new() }
    sub create_item   { Easy::Item->new() }
}

package NormalFactory {
    use Moo;
    with 'DifficultyFactory::Role';

    sub difficulty_name {'NORMAL'}

    sub create_enemy  { Normal::Enemy->new() }
    sub create_weapon { Normal::Weapon->new() }
    sub create_item   { Normal::Item->new() }
}

package HardFactory {
    use Moo;
    with 'DifficultyFactory::Role';

    sub difficulty_name {'HARD'}

    sub create_enemy  { Hard::Enemy->new() }
    sub create_weapon { Hard::Weapon->new() }
    sub create_item   { Hard::Item->new() }
}

# =====================
# ゲームエンジン（健康版）
# =====================

package GameEngine {
    use Moo;

    # 依存注入: Abstract Factoryを受け取る
    has factory => (
        is       => 'ro',
        required => 1,
        isa      => sub {
            die "DifficultyFactory::Role を does していません"
                unless $_[0]->does('DifficultyFactory::Role');
        },
    );

    # if-else なし！Factory 経由で生成
    sub create_enemy  ($self) { $self->factory->create_enemy }
    sub create_weapon ($self) { $self->factory->create_weapon }
    sub create_item   ($self) { $self->factory->create_item }

    sub run_battle ($self) {
        my $enemy  = $self->create_enemy;
        my $weapon = $self->create_weapon;
        my $item   = $self->create_item;

        say "=== " . $self->factory->difficulty_name . " モード ===";
        say "敵: " . $enemy->name . " (HP:" . $enemy->hp . ")";
        say "武器: " . $weapon->name . " (ATK:" . $weapon->atk . ")";
        say "回復: " . $item->name . " (" . $item->effect . ")";
        say "";
    }
}

# =====================
# メイン処理
# =====================

package main;

say "【After】難易度システム - Abstract Factory版";
say "=" x 50;
say "";

# 難易度切り替え: Factoryを差し替えるだけ！
my @factories = (EasyFactory->new(), NormalFactory->new(), HardFactory->new(),);

for my $factory (@factories) {
    my $game = GameEngine->new(factory => $factory);
    $game->run_battle();
}

say "【整合性保証】製品ファミリー不整合は構造上不可能";
say "-" x 50;
say "EasyFactory は Easy::Enemy, Easy::Weapon, Easy::Item しか生成できない";
say "→ 間違った組み合わせを作ることが物理的に不可能！";
say "";

# 新難易度追加のデモ（NightmareFactory）
say "【拡張性】新難易度 Nightmare 追加";
say "-" x 50;

# Nightmare 製品ファミリー（追加は1ファイル = 1Factoryのみ）
package Nightmare::Enemy {
    use Moo;
    with 'Enemy::Role';
    has '+name' => (default => 'カオスドラゴン');
    has '+hp'   => (default => 500);
    sub attack_power {100}
}

package Nightmare::Weapon {
    use Moo;
    with 'Weapon::Role';
    has '+name' => (default => '神殺しの剣');
    has '+atk'  => (default => 150);
}

package Nightmare::Item {
    use Moo;
    with 'Item::Role';
    has '+name'   => (default => '賢者の石');
    has '+effect' => (default => '全回復+復活');
}

package NightmareFactory {
    use Moo;
    with 'DifficultyFactory::Role';

    sub difficulty_name {'NIGHTMARE'}

    sub create_enemy  { Nightmare::Enemy->new() }
    sub create_weapon { Nightmare::Weapon->new() }
    sub create_item   { Nightmare::Item->new() }
}

package main;

# 既存コードへの変更ゼロで新難易度追加！
my $nightmare_game = GameEngine->new(factory => NightmareFactory->new());
$nightmare_game->run_battle();

say "→ 既存の GameEngine, Factory には一切手を加えていない！";
say "→ Open-Closed Principle (OCP) の実現";

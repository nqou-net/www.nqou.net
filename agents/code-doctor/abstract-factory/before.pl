#!/usr/bin/env perl
# ==========================================================
# Before: Abstract Factory 適用前
# 難易度切り替えで多数の修正が必要な状態
# ==========================================================
use v5.40;

# =====================
# 製品クラス（直接定義）
# =====================

package EasyEnemy {
    use Moo;
    has name => (is => 'ro', default => 'スライム');
    has hp   => (is => 'ro', default => 30);
    sub attack_power {5}
}

package NormalEnemy {
    use Moo;
    has name => (is => 'ro', default => 'ゴブリン');
    has hp   => (is => 'ro', default => 80);
    sub attack_power {15}
}

package HardEnemy {
    use Moo;
    has name => (is => 'ro', default => 'ドラゴン');
    has hp   => (is => 'ro', default => 200);
    sub attack_power {40}
}

package EasyWeapon {
    use Moo;
    has name => (is => 'ro', default => '木の剣');
    has atk  => (is => 'ro', default => 10);
}

package NormalWeapon {
    use Moo;
    has name => (is => 'ro', default => '鉄の剣');
    has atk  => (is => 'ro', default => 30);
}

package HardWeapon {
    use Moo;
    has name => (is => 'ro', default => '炎の刀');
    has atk  => (is => 'ro', default => 80);
}

package EasyItem {
    use Moo;
    has name   => (is => 'ro', default => '薬草');
    has effect => (is => 'ro', default => '20回復');
}

package NormalItem {
    use Moo;
    has name   => (is => 'ro', default => 'ポーション');
    has effect => (is => 'ro', default => '50回復');
}

package HardItem {
    use Moo;
    has name   => (is => 'ro', default => 'エリクサー');
    has effect => (is => 'ro', default => '全回復');
}

# =====================
# ゲームエンジン（症状: if-else地獄）
# =====================

package GameEngine {
    use Moo;

    has difficulty => (is => 'ro', required => 1);

    # 症状1: 具体クラス直接生成症
    # 難易度ごとに分岐し、具体クラスを直接 new している
    sub create_enemy ($self) {
        if ($self->difficulty eq 'easy') {
            return EasyEnemy->new();    # ← 直接生成！
        }
        elsif ($self->difficulty eq 'normal') {
            return NormalEnemy->new();    # ← 直接生成！
        }
        elsif ($self->difficulty eq 'hard') {
            return HardEnemy->new();      # ← 直接生成！
        }
        die "Unknown difficulty: " . $self->difficulty;
    }

    sub create_weapon ($self) {
        if ($self->difficulty eq 'easy') {
            return EasyWeapon->new();
        }
        elsif ($self->difficulty eq 'normal') {
            return NormalWeapon->new();
        }
        elsif ($self->difficulty eq 'hard') {
            return HardWeapon->new();
        }
        die "Unknown difficulty: " . $self->difficulty;
    }

    sub create_item ($self) {
        if ($self->difficulty eq 'easy') {
            return EasyItem->new();
        }
        elsif ($self->difficulty eq 'normal') {
            return NormalItem->new();
        }
        elsif ($self->difficulty eq 'hard') {
            return HardItem->new();
        }
        die "Unknown difficulty: " . $self->difficulty;
    }

    # 症状2: 製品ファミリー不整合症
    # 間違った組み合わせが可能（バグの温床）
    sub create_mismatched_set ($self) {

        # ← 意図せず異なる難易度を混在させてしまう可能性！
        my $enemy  = EasyEnemy->new();     # Easy敵
        my $weapon = HardWeapon->new();    # Hard武器（不整合！）
        my $item   = NormalItem->new();    # Normal回復（不整合！）
        return {enemy => $enemy, weapon => $weapon, item => $item};
    }

    sub run_battle ($self) {
        my $enemy  = $self->create_enemy;
        my $weapon = $self->create_weapon;
        my $item   = $self->create_item;

        say "=== " . uc($self->difficulty) . " モード ===";
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

say "【Before】難易度システム - if/else地獄版";
say "=" x 50;
say "";

# 症状の実演: 難易度ごとにif-elseで分岐
for my $difficulty (qw(easy normal hard)) {
    my $game = GameEngine->new(difficulty => $difficulty);
    $game->run_battle();
}

# 致命的なバグ: 製品ファミリーの不整合
say "【バグ実演】製品ファミリー不整合";
say "-" x 50;
my $game = GameEngine->new(difficulty => 'easy');
my $set  = $game->create_mismatched_set();
say "敵: " . $set->{enemy}->name . " (Easy)";
say "武器: " . $set->{weapon}->name . " (Hard!?)";
say "回復: " . $set->{item}->name . " (Normal!?)";
say "";
say "→ Easy敵にHard武器...ゲームバランス崩壊！";

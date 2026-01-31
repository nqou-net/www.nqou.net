#!/usr/bin/env perl
use v5.34;
use strict;
use warnings;
use feature "signatures";
no warnings "experimental::signatures";

# 第5章: Strategyパターン導入
# ====================
# 難易度ロール（Strategy Interface）
# ====================

package DifficultyRole {
    use Moo::Role;

    requires 'name';
    requires 'monster_power';    # モンスターの強さ倍率
    requires 'trap_damage';      # 罠のダメージ
    requires 'reward_bonus';     # 報酬ボーナス
}

# ====================
# 難易度戦略クラス群
# ====================

package EasyDifficulty {
    use Moo;
    with 'DifficultyRole';

    sub name($self)          {'イージー'}
    sub monster_power($self) {0.5}
    sub trap_damage($self)   { int(rand(5)) + 1 }
    sub reward_bonus($self)  {1.5}
}

package NormalDifficulty {
    use Moo;
    with 'DifficultyRole';

    sub name($self)          {'ノーマル'}
    sub monster_power($self) {1.0}
    sub trap_damage($self)   { int(rand(15)) + 5 }
    sub reward_bonus($self)  {1.0}
}

package HardDifficulty {
    use Moo;
    with 'DifficultyRole';

    sub name($self)          {'ハード'}
    sub monster_power($self) {2.0}
    sub trap_damage($self)   { int(rand(30)) + 15 }
    sub reward_bonus($self)  {0.8}
}

# ====================
# 基底部屋クラス（難易度対応版）
# ====================

package BaseRoom {
    use Moo;

    has name       => (is => 'ro', required => 1);
    has difficulty => (is => 'ro', required => 1);    # Strategy

    sub enter($self) {
        $self->_on_enter;
        $self->_run_event;
        $self->_give_reward;
        $self->_on_exit;
    }

    sub _on_enter($self) {
        say "【" . $self->name . "】に入った！（" . $self->difficulty->name . "モード）";
    }

    sub _run_event($self) {
        die "サブクラスで_run_eventを実装してください";
    }

    sub _give_reward($self) { }

    sub _on_exit($self) {
        say "部屋をクリアした！\n";
    }
}

# ====================
# 具象部屋クラス群（難易度対応版）
# ====================

package BattleRoom {
    use Moo;
    extends 'BaseRoom';

    has '+name' => (default => '戦闘の間');

    sub _run_event($self) {
        my @monsters = ('ゴブリン', 'スライム', 'コウモリ');
        my $monster  = $monsters[int(rand(@monsters))];
        my $power    = int(10 * $self->difficulty->monster_power);
        say "  $monster (強さ: $power) が現れた！";
        say "  $monster を倒した！";
    }

    sub _give_reward($self) {
        my $base_exp = int(rand(50)) + 10;
        my $exp      = int($base_exp * $self->difficulty->reward_bonus);
        say "  経験値 $exp を獲得！";
    }
}

package TreasureRoom {
    use Moo;
    extends 'BaseRoom';

    has '+name' => (default => '宝物庫');

    sub _run_event($self) {
        say "  宝箱を発見！";
    }

    sub _give_reward($self) {
        my $base_gold = int(rand(100)) + 50;
        my $gold      = int($base_gold * $self->difficulty->reward_bonus);
        say "  金貨 $gold 枚を手に入れた！";
    }
}

package TrapRoom {
    use Moo;
    extends 'BaseRoom';

    has '+name' => (default => '罠の間');

    sub _run_event($self) {
        my @traps  = ('落とし穴', '毒矢', '閃光');
        my $trap   = $traps[int(rand(@traps))];
        my $damage = $self->difficulty->trap_damage;
        say "  罠だ！ $trap！";
        say "  $damage ダメージを受けた...";
    }
}

# ====================
# 部屋ファクトリ（難易度対応版）
# ====================

package RoomFactory {
    use Moo;

    has difficulty => (is => 'ro', required => 1);

    has registry => (
        is      => 'ro',
        default => sub {
            {
                battle   => 'BattleRoom',
                treasure => 'TreasureRoom',
                trap     => 'TrapRoom',
            }
        }
    );

    sub create_room($self, $type) {
        my $class = $self->registry->{$type}
            or die "Unknown room type: $type";
        return $class->new(difficulty => $self->difficulty);
    }
}

# ====================
# メイン処理
# ====================

package main {

    # 難易度を選択
    my $difficulty = HardDifficulty->new;

    say "=== ダンジョン探索開始（" . $difficulty->name . "）===\n";

    my $factory    = RoomFactory->new(difficulty => $difficulty);
    my @room_types = ('battle', 'treasure', 'trap');

    for my $type (@room_types) {
        my $room = $factory->create_room($type);
        $room->enter;
    }

    say "=== 探索終了 ===";
}

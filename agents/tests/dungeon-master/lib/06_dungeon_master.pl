#!/usr/bin/env perl
use v5.34;
use strict;
use warnings;
use feature "signatures";
no warnings "experimental::signatures";

# 第6章: 統合版ダンジョンマスター
# ====================
# 難易度戦略（Strategy）
# ====================

package DifficultyRole {
    use Moo::Role;
    requires 'name';
    requires 'monster_power';
    requires 'trap_damage';
    requires 'reward_bonus';
}

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
# 基底部屋クラス（Template Method）
# ====================

package BaseRoom {
    use Moo;
    has name       => (is => 'ro', required => 1);
    has difficulty => (is => 'ro', required => 1);

    sub enter($self) {
        $self->_on_enter;
        $self->_run_event;
        $self->_give_reward;
        $self->_on_exit;
    }

    sub _on_enter($self) {
        say "【" . $self->name . "】に入った！";
    }
    sub _run_event($self)   { die "Implement in subclass" }
    sub _give_reward($self) { }
    sub _on_exit($self)     { say "部屋をクリアした！\n" }
}

# ====================
# 具象部屋クラス群
# ====================

package BattleRoom {
    use Moo;
    extends 'BaseRoom';
    has '+name' => (default => '戦闘の間');

    sub _run_event($self) {
        my @monsters = ('ゴブリン', 'スライム', 'コウモリ', 'オーク', 'スケルトン');
        my $monster  = $monsters[int(rand(@monsters))];
        my $power    = int(10 * $self->difficulty->monster_power);
        say "  🗡️ $monster (強さ: $power) が現れた！";
        say "  ⚔️ $monster を倒した！";
    }

    sub _give_reward($self) {
        my $base_exp = int(rand(50)) + 10;
        my $exp      = int($base_exp * $self->difficulty->reward_bonus);
        say "  ✨ 経験値 $exp を獲得！";
    }
}

package TreasureRoom {
    use Moo;
    extends 'BaseRoom';
    has '+name' => (default => '宝物庫');

    sub _run_event($self) {
        say "  📦 宝箱を発見！";
    }

    sub _give_reward($self) {
        my @items     = ('回復薬', '聖なる剣', '魔法の盾', 'エリクサー', 'ドラゴンの鱗');
        my $item      = $items[int(rand(@items))];
        my $base_gold = int(rand(100)) + 50;
        my $gold      = int($base_gold * $self->difficulty->reward_bonus);
        say "  💎 $item を手に入れた！";
        say "  💰 金貨 $gold 枚を獲得！";
    }
}

package TrapRoom {
    use Moo;
    extends 'BaseRoom';
    has '+name' => (default => '罠の間');

    sub _run_event($self) {
        my @traps  = ('落とし穴', '毒矢', '閃光', '爆発', '凍結');
        my $trap   = $traps[int(rand(@traps))];
        my $damage = $self->difficulty->trap_damage;
        say "  ⚠️ 罠だ！ $trap！";
        say "  💥 $damage ダメージを受けた...";
    }
}

# ====================
# 部屋ファクトリ（Factory Method）
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

    sub register($self, $type, $class) {
        $self->registry->{$type} = $class;
    }
}

# ====================
# ダンジョンマスター（統合クラス）
# ====================

package DungeonMaster {
    use Moo;

    has difficulty => (is => 'ro', required => 1);
    has room_count => (is => 'ro', default  => 5);
    has factory    => (is => 'lazy');

    sub _build_factory($self) {
        RoomFactory->new(difficulty => $self->difficulty);
    }

    sub generate_dungeon($self) {
        my @types = ('battle', 'treasure', 'trap');
        my @rooms;

        for (1 .. $self->room_count) {
            my $type = $types[int(rand(@types))];
            push @rooms, $self->factory->create_room($type);
        }

        return @rooms;
    }

    sub run($self) {
        say "╔══════════════════════════════════════╗";
        say "║     ダンジョンマスター               ║";
        say "║     難易度: " . $self->difficulty->name . "                    ║";
        say "╚══════════════════════════════════════╝\n";

        my @rooms = $self->generate_dungeon;
        my $floor = 1;

        for my $room (@rooms) {
            say "--- 第${floor}層 ---";
            $room->enter;
            $floor++;
        }

        say "╔══════════════════════════════════════╗";
        say "║     🎉 ダンジョン踏破おめでとう！    ║";
        say "╚══════════════════════════════════════╝";
    }
}

# ====================
# メイン処理
# ====================

package main {

    # 難易度を選択（ここを変えるだけでゲームバランスが変わる）
    my $difficulty = NormalDifficulty->new;

    my $game = DungeonMaster->new(
        difficulty => $difficulty,
        room_count => 5,
    );

    $game->run;
}

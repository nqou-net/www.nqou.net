#!/usr/bin/env perl
use v5.34;
use strict;
use warnings;
use feature "signatures";
no warnings "experimental::signatures";

# 第7章: 拡張版（ShopRoom + NightmareDifficulty）
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

# 新しい難易度を追加（既存コード無修正）
package NightmareDifficulty {
    use Moo;
    with 'DifficultyRole';

    sub name($self)          {'🔥悪夢🔥'}
    sub monster_power($self) {5.0}                      # モンスター5倍！
    sub trap_damage($self)   { int(rand(100)) + 50 }    # 罠も激痛
    sub reward_bonus($self)  {2.0}                      # 報酬2倍（釣り合い）
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

# 新しい部屋タイプを追加（既存コード無修正）
package ShopRoom {
    use Moo;
    extends 'BaseRoom';

    has '+name' => (default => '旅の商人');

    sub _on_enter($self) {
        say "【" . $self->name . "】に出会った！";
        say "  🛒 「いらっしゃい、何をお求めかな？」";
    }

    sub _run_event($self) {
        my @goods = ({name => '回復薬', price => 50}, {name => '解毒剤', price => 30}, {name => '松明', price => 20},);
        say "  📋 商品リスト:";
        for my $item (@goods) {
            say "    - $item->{name}: $item->{price}G";
        }
    }

    sub _give_reward($self) {

        # 買い物なので報酬はなし（購入処理は省略）
        say "  💬 「またのお越しを！」";
    }

    sub _on_exit($self) {
        say "商人と別れた。\n";
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
# メイン処理
# ====================

package main {
    my $difficulty = NightmareDifficulty->new;

    my $factory = RoomFactory->new(difficulty => $difficulty);
    $factory->register('shop', 'ShopRoom');

    my @room_types = ('battle', 'shop', 'trap');

    say "=== 悪夢のダンジョン ===\n";
    for my $type (@room_types) {
        my $room = $factory->create_room($type);
        $room->enter;
    }
}

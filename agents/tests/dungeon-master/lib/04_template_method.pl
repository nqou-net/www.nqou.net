#!/usr/bin/env perl
use v5.34;
use strict;
use warnings;
use feature "signatures";
no warnings "experimental::signatures";

# 第4章: Template Methodパターン導入
# ====================
# 基底部屋クラス（Template Method）
# ====================

package BaseRoom {
    use Moo;

    has name => (is => 'ro', required => 1);

    # Template Method: 処理の骨格を定義
    sub enter($self) {
        $self->_on_enter;       # 1. 入室
        $self->_run_event;      # 2. イベント（サブクラスで実装）
        $self->_give_reward;    # 3. 報酬
        $self->_on_exit;        # 4. 退室
    }

    # フック: 入室時（オーバーライド可能）
    sub _on_enter($self) {
        say "【" . $self->name . "】に入った！";
    }

    # 抽象メソッド: サブクラスで必ず実装
    sub _run_event($self) {
        die "サブクラスで_run_eventを実装してください";
    }

    # フック: 報酬付与（デフォルトは何もしない）
    sub _give_reward($self) {

        # デフォルトでは何もしない（オーバーライド可能）
    }

    # フック: 退室時
    sub _on_exit($self) {
        say "部屋をクリアした！\n";
    }
}

# ====================
# 具象部屋クラス群
# ====================

package BattleRoom {
    use Moo;
    extends 'BaseRoom';

    has '+name' => (default => '戦闘の間');

    sub _run_event($self) {
        my @monsters = ('ゴブリン', 'スライム', 'コウモリ');
        my $monster  = $monsters[int(rand(@monsters))];
        say "  $monster が現れた！";
        say "  $monster を倒した！";
    }

    sub _give_reward($self) {
        my $exp = int(rand(50)) + 10;
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
        my @items = ('回復薬', '金貨100枚', '古びた剣');
        my $item  = $items[int(rand(@items))];
        say "  $item を手に入れた！";
    }
}

package TrapRoom {
    use Moo;
    extends 'BaseRoom';

    has '+name' => (default => '罠の間');

    sub _run_event($self) {
        my @traps = ('落とし穴', '毒矢', '閃光');
        my $trap  = $traps[int(rand(@traps))];
        say "  罠だ！ $trap！";
        say "  ダメージを受けた...";
    }

    # 罠の間には報酬なし（デフォルトのまま）
}

# ====================
# 部屋ファクトリ
# ====================

package RoomFactory {
    use Moo;

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
        return $class->new;
    }
}

# ====================
# メイン処理
# ====================

package main {
    say "=== ダンジョン探索開始 ===\n";

    my $factory    = RoomFactory->new;
    my @room_types = ('battle', 'treasure', 'trap');

    for my $type (@room_types) {
        my $room = $factory->create_room($type);
        $room->enter;
    }

    say "=== 探索終了 ===";
}

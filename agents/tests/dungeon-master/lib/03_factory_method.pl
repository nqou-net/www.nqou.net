#!/usr/bin/env perl
use v5.34;
use strict;
use warnings;
use feature "signatures";
no warnings "experimental::signatures";

# 第3章: Factory Methodパターン導入
# ====================
# 部屋クラス群
# ====================

package BattleRoom {
    use Moo;

    has name => (is => 'ro', default => '戦闘の間');

    sub enter($self) {
        say "【" . $self->name . "】に入った！";
        my @monsters = ('ゴブリン', 'スライム', 'コウモリ');
        my $monster  = $monsters[int(rand(@monsters))];
        say "  $monster が現れた！";
        say "  $monster を倒した！";
        say "部屋をクリアした！\n";
    }
}

package TreasureRoom {
    use Moo;

    has name => (is => 'ro', default => '宝物庫');

    sub enter($self) {
        say "【" . $self->name . "】に入った！";
        my @items = ('回復薬', '金貨100枚', '古びた剣');
        my $item  = $items[int(rand(@items))];
        say "  宝箱を発見！";
        say "  $item を手に入れた！";
        say "部屋をクリアした！\n";
    }
}

package TrapRoom {
    use Moo;

    has name => (is => 'ro', default => '罠の間');

    sub enter($self) {
        say "【" . $self->name . "】に入った！";
        my @traps = ('落とし穴', '毒矢', '閃光');
        my $trap  = $traps[int(rand(@traps))];
        say "  罠だ！ $trap！";
        say "  ダメージを受けた...";
        say "部屋をクリアした！\n";
    }
}

# ====================
# 部屋ファクトリ（Factory Method）
# ====================

package RoomFactory {
    use Moo;

    # 部屋タイプからクラスへのマッピング
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

    # Factory Method: 部屋タイプ名から部屋オブジェクトを生成
    sub create_room($self, $type) {
        my $class = $self->registry->{$type}
            or die "Unknown room type: $type";
        return $class->new;
    }

    # 新しい部屋タイプを登録
    sub register($self, $type, $class) {
        $self->registry->{$type} = $class;
    }
}

# ====================
# メイン処理
# ====================

package main {
    say "=== ダンジョン探索開始 ===\n";

    my $factory    = RoomFactory->new;
    my @room_types = ('battle', 'treasure', 'trap', 'battle', 'treasure');

    for my $type (@room_types) {
        my $room = $factory->create_room($type);
        $room->enter;
    }

    say "=== 探索終了 ===";
}

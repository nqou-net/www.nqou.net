#!/usr/bin/env perl
use v5.34;
use strict;
use warnings;
use feature "signatures";
no warnings "experimental::signatures";

# 第2章: if/elseで部屋を判定（問題版）
sub create_room($type) {
    if ($type eq 'battle') {
        return {
            name  => '戦闘の間',
            event => sub {
                my @monsters = ('ゴブリン', 'スライム', 'コウモリ');
                my $monster  = $monsters[int(rand(@monsters))];
                say "  $monster が現れた！";
                say "  $monster を倒した！";
            }
        };
    }
    elsif ($type eq 'treasure') {
        return {
            name  => '宝物庫',
            event => sub {
                my @items = ('回復薬', '金貨100枚', '古びた剣');
                my $item  = $items[int(rand(@items))];
                say "  宝箱を発見！";
                say "  $item を手に入れた！";
            }
        };
    }
    elsif ($type eq 'trap') {
        return {
            name  => '罠の間',
            event => sub {
                my @traps = ('落とし穴', '毒矢', '閃光');
                my $trap  = $traps[int(rand(@traps))];
                say "  罠だ！ $trap！";
                say "  ダメージを受けた...";
            }
        };
    }
    else {
        die "Unknown room type: $type";
    }
}

sub enter_room($room) {
    say "【" . $room->{name} . "】に入った！";
    $room->{event}->();
    say "部屋をクリアした！\n";
}

# メイン処理
package main {
    say "=== ダンジョン探索開始 ===\n";

    my @room_types = ('battle', 'treasure', 'trap', 'battle', 'treasure');

    for my $type (@room_types) {
        my $room = create_room($type);
        enter_room($room);
    }

    say "=== 探索終了 ===";
}

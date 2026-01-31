#!/usr/bin/env perl
use v5.34;
use strict;
use warnings;
use feature "signatures";
no warnings "experimental::signatures";

# 第1章: 戦闘部屋クラス（基本版）
package BattleRoom {
    use Moo;
    
    has name => (is => 'ro', default => '戦闘の間');
    
    sub enter($self) {
        say "【" . $self->name . "】に入った！";
        $self->_battle();
        say "部屋をクリアした！\n";
    }
    
    sub _battle($self) {
        my @monsters = ('ゴブリン', 'スライム', 'コウモリ');
        my $monster = $monsters[int(rand(@monsters))];
        say "  $monster が現れた！";
        say "  $monster を倒した！";
    }
}

# メイン処理
package main {
    say "=== ダンジョン探索開始 ===\n";
    
    my $room = BattleRoom->new;
    $room->enter;
    
    say "=== 探索終了 ===";
}

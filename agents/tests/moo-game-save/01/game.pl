#!/usr/bin/env perl
# Perl v5.36 以降
# 外部依存: Moo

use v5.36;
use FindBin;
use lib "$FindBin::Bin/lib";
use Player;

# ゲームループのデモ
my $player = Player->new;

say "=== ゲーム開始 ===";
$player->show_status;

say "森へ移動...";
$player->move_to('森');
$player->show_status;

say "スライムと戦闘！";
$player->take_damage(30);
say "30のダメージを受けた！";
$player->show_status;

if ($player->is_alive) {
    say "スライムを倒した！";
    $player->earn_gold(50);
    say "50Gを手に入れた！";
    $player->show_status;
}

say "洞窟へ移動...";
$player->move_to('洞窟');
$player->show_status;

say "ドラゴンと戦闘！";
$player->take_damage(80);
say "80のダメージを受けた！";
$player->show_status;

if (!$player->is_alive) {
    say "=== GAME OVER ===";
}

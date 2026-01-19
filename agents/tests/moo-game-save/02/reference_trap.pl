#!/usr/bin/env perl
# Perl v5.36 以降
# 外部依存: Moo

use v5.36;
use FindBin;
use lib "$FindBin::Bin/lib";
use Player;

my $player = Player->new;

say "=== ゲーム開始 ===";
say "HP: " . $player->hp;
$player->show_items;
say "";

say "薬草を拾った！";
$player->add_item('薬草');
$player->show_items;
say "";

# 状態を保存（単純な変数コピー）
say "=== セーブポイント ===";
my $saved_hp    = $player->hp;
my $saved_items = $player->items;  # これは参照のコピー
say "状態を保存しました";
say "";

say "毒薬を拾った！";
$player->add_item('毒薬');
$player->show_items;
say "";

say "毒薬を飲んでゲームオーバー！";
$player->take_damage(100);
say "HP: " . $player->hp;
say "";

# 復元
say "=== セーブポイントから復元 ===";
$player->hp($saved_hp);
$player->items($saved_items);

say "HP: " . $player->hp;
$player->show_items;  # 期待: 薬草のみ、実際: 薬草、毒薬
say "";
say "※ 毒薬が残っている！これが参照コピーの罠です";

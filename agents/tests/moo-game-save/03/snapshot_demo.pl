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
    $player->add_item("薬草");
    say "薬草を手に入れた！";
    $player->show_status;
}

# スナップショットを保存
say "=== セーブポイント ===";
my $snapshot = $player->save_snapshot;
say "状態を保存しました";
say "保存された状態:";
{
    say "HP: " . $snapshot->hp;
    say "所持金: " . $snapshot->gold . "G";
    say "位置: " . $snapshot->position;
    my $items = $snapshot->items;
    my $items_str = ($items->@*) ? join(', ', $items->@*) : 'なし';
    say "所持品: " . $items_str;
    say "";
}
say "洞窟へ移動...";
$player->move_to('洞窟');
$player->add_item("毒消し草");
say "毒消し草を手に入れた！";
$player->show_status;

say "ドラゴンと戦闘！";
$player->take_damage(80);
say "80のダメージを受けた！";
$player->show_status;

# スナップショットの内容は変わっていないことを確認
say "=== スナップショットの確認 ===";
say "保存された状態は変わっていない:";
{
    say "HP: " . $snapshot->hp;
    say "所持金: " . $snapshot->gold . "G";
    say "位置: " . $snapshot->position;
    my $items = $snapshot->items;
    my $items_str = ($items->@*) ? join(', ', $items->@*) : 'なし';
    say "所持品: " . $items_str;
    say "";
}

# スナップショットを変更しようとするとエラーになる
say "スナップショットを変更しようとすると...";
eval {
    $snapshot->hp(999);
};
if ($@) {
    say "エラー: スナップショットは変更できません";
    say "（is => 'ro'で保護されています）";
}

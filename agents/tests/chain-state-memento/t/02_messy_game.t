#!/usr/bin/env perl
use v5.36;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

# 第2回: if/else肥大化版のテスト

subtest 'messy_game.pl - 基本動作' => sub {
    require 'messy_game.pl';

    my $game = MessyGame->new;

    is $game->location,  '森の入り口', '初期位置';
    is $game->hp,        100,     '初期HP';
    is $game->in_battle, 0,       '戦闘なし';

    # 移動
    $game->process_command('北');
    is $game->location, '小道', '移動成功';

    # 調べる（アイテム取得なし）
    my $result = $game->process_command('調べる');
    like $result, qr/何も見つからない/, '小道では何も見つからない';

    # 小屋に移動して調べる
    $game->process_command('東');
    $result = $game->process_command('調べる');
    like $result, qr/古びた鍵/, '鍵を発見';

    # インベントリ確認
    $result = $game->process_command('持ち物');
    like $result, qr/古びた鍵/, 'インベントリに鍵がある';
};

subtest 'messy_game.pl - 戦闘' => sub {
    my $game = MessyGame->new;
    $game->location('小道');

    # 泉に行くと戦闘
    my $result = $game->process_command('北');
    like $result, qr/ゴブリン.*戦闘開始/, '戦闘開始';
    is $game->in_battle, 1, '戦闘中';

    # 戦闘中は移動不可
    $result = $game->process_command('南');
    like $result, qr/戦闘中/, '戦闘中メッセージ';

    # 逃げる
    $result = $game->process_command('逃げる');
    like $result, qr/逃げ出した/, '逃走成功';
    is $game->in_battle, 0, '戦闘終了';
};

done_testing;

#!/usr/bin/env perl
use v5.36;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

# 第1回: シンプルなゲームループのテスト

subtest 'simple_game.pl - 基本動作' => sub {
    require 'simple_game.pl';

    my $game = Game->new;

    is $game->location, '森の入り口', '初期位置は森の入り口';
    is $game->running,  1,       'ゲーム実行中';

    # 移動テスト
    my $result = $game->process_command('北');
    like $result, qr/北へ進んだ/, '北への移動';
    is $game->location, '小道', '小道に到着';

    # 無効な方向
    $result = $game->process_command('西');
    like $result, qr/進めない/, '無効な方向';

    # ヘルプ
    $result = $game->process_command('ヘルプ');
    like $result, qr/コマンド/, 'ヘルプ表示';

    # 終了
    $result = $game->process_command('終了');
    is $game->running, 0, 'ゲーム終了';
};

done_testing;

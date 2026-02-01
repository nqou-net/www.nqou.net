#!/usr/bin/env perl
use v5.36;
use warnings;
use utf8;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

# 第7回: 拡張性テスト

# adventure.pl を先に読み込み（GameStateRole などが必要）
require 'adventure.pl';

use ShopState;
use BuyHandler;

subtest 'ShopState - 基本動作' => sub {
    my $state = ShopState->new;

    is $state->name, 'ショップ', '状態名';

    my $game = AdventureGame->new;
    $game->context->{gold} = 50;

    # 一覧表示
    my $result = $state->process_command($game, '一覧');
    like $result->{message}, qr/回復薬/, '商品一覧に回復薬';
    like $result->{message}, qr/50/,  '所持金表示';
};

subtest 'ShopState - 購入' => sub {
    my $state = ShopState->new;
    my $game  = AdventureGame->new;
    $game->context->{gold} = 100;

    my $result = $state->process_command($game, '買う 回復薬');
    like $result->{message}, qr/購入/, '購入メッセージ';
    ok grep { $_ eq '回復薬' } @{$game->context->{inventory}}, 'インベントリに追加';
    is $game->context->{gold}, 90, 'ゴールド減少';

    # ゴールド不足
    $game->context->{gold} = 5;
    $result = $state->process_command($game, '買う 回復薬');
    like $result->{message}, qr/足りない/, '購入失敗';
};

subtest 'ShopState - 売却' => sub {
    my $state = ShopState->new;
    my $game  = AdventureGame->new;
    $game->context->{gold}      = 0;
    $game->context->{inventory} = ['回復薬'];

    my $result = $state->process_command($game, '売る 回復薬');
    like $result->{message}, qr/売った/, '売却メッセージ';
    ok $game->context->{gold} > 0, 'ゴールド増加';
    is scalar(@{$game->context->{inventory}}), 0, 'インベントリから削除';
};

subtest 'BuyHandler - ショップ遷移' => sub {
    my $handler = BuyHandler->new;
    my $game    = AdventureGame->new;
    $game->context->{location} = '古い小屋';

    ok $handler->can_handle($game, '買い物'),  '買い物コマンド認識';
    ok $handler->can_handle($game, 'ショップ'), 'ショップコマンド認識';

    $handler->handle($game, 'ショップ');
    is ref($game->state), 'ShopState', 'ショップモードに遷移';

    # 別の場所では遷移不可
    my $game2 = AdventureGame->new;
    $game2->context->{location} = '森の入り口';
    my $result = $handler->handle($game2, 'ショップ');
    like $result->{message}, qr/ショップがない/, '場所制限';
};

subtest '拡張性の証明 - 既存コード無修正' => sub {

    # 既存のゲームにショップハンドラを追加
    my $game = AdventureGame->new;

    # ハンドラチェーンにBuyHandlerを追加
    my $buy_handler    = BuyHandler->new;
    my $original_chain = $game->handler_chain;

    # チェーンの末尾に追加（簡易的な方法）
    my $current = $original_chain;
    while ($current->has_next) {
        $current = $current->next_handler;
    }
    $current->set_next($buy_handler);

    # 既存機能が動作することを確認
    my $result = $game->state->process_command($game, '北');
    is $game->context->{location}, '小道', '既存の移動機能';

    $result = $game->state->process_command($game, '東');
    is $game->context->{location}, '古い小屋', '小屋へ移動';

    # 新機能（ショップ）も動作
    $result = $game->state->process_command($game, 'ショップ');
    is ref($game->state), 'ShopState', 'ショップ遷移成功';

    pass '既存コードを修正せずにショップ機能を追加できた（OCP）';
};

done_testing;

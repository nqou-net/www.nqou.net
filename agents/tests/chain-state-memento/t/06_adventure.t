#!/usr/bin/env perl
use v5.36;
use warnings;
use utf8;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

# 第6回: 統合版のテスト

# adventure.pl のパッケージを読み込み
require 'adventure.pl';

subtest 'AdventureGame - 初期化' => sub {
    my $game = AdventureGame->new;

    is $game->context->{location}, '森の入り口',            '初期位置';
    is $game->context->{hp},       100,                '初期HP';
    is ref($game->state),          'ExplorationState', '探索モード';
    ok defined $game->save_manager, 'セーブマネージャー存在';
};

subtest 'AdventureGame - ハンドラチェーンによる移動' => sub {
    my $game = AdventureGame->new;

    my $result = $game->state->process_command($game, '北');
    is $game->context->{location}, '小道', '移動成功';

    $result = $game->state->process_command($game, '東');
    is $game->context->{location}, '古い小屋', '東へ移動';

    $result = $game->state->process_command($game, '調べる');
    ok grep { $_ eq '古びた鍵' } @{$game->context->{inventory}}, '鍵取得';
};

subtest 'AdventureGame - 状態遷移' => sub {
    my $game = AdventureGame->new;
    $game->context->{location} = '小道';

    # 泉に行くと戦闘開始
    $game->state->process_command($game, '北');
    is ref($game->state),        'BattleState', '戦闘状態に遷移';
    is $game->state->enemy_name, 'ゴブリン',        'ゴブリン戦';

    # 逃げる
    $game->state->process_command($game, '逃げる');
    is ref($game->state),          'ExplorationState', '探索モードに戻る';
    is $game->context->{location}, '小道',               '小道に戻る';
};

subtest 'AdventureGame - セーブ/ロード' => sub {
    my $game = AdventureGame->new;

    # 移動してセーブ
    $game->state->process_command($game, '北');
    $game->state->process_command($game, 'セーブ');

    is scalar(@{$game->save_manager->saves}), 1, 'セーブ作成';

    # さらに移動
    $game->state->process_command($game, '東');
    is $game->context->{location}, '古い小屋', '小屋に移動';

    # ロード
    $game->state->process_command($game, 'ロード');
    is $game->context->{location}, '小道', 'セーブ時点に戻る';
};

subtest 'AdventureGame - アイテム使用' => sub {
    my $game = AdventureGame->new;
    $game->context->{location} = '古い小屋';

    # 鍵を取得
    $game->state->process_command($game, '調べる');
    ok grep { $_ eq '古びた鍵' } @{$game->context->{inventory}}, '鍵取得';

    # 泉で鍵を使う
    $game->context->{location} = '泉';
    $game->context->{defeated}{'ゴブリン'} = 1;     # 戦闘スキップ用

    $game->state->process_command($game, '使う 古びた鍵');
    ok $game->context->{unlocked}{'宝物庫'},                       '宝物庫解錠';
    ok !(grep { $_ eq '古びた鍵' } @{$game->context->{inventory}}), '鍵消費';
};

done_testing;

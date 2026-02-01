#!/usr/bin/env perl
use v5.36;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

# 第3回: Chain of Responsibility のテスト

use CommandHandler;
use MoveHandler;
use ExamineHandler;
use HelpHandler;

subtest 'MoveHandler' => sub {
    my $handler = MoveHandler->new;
    my $context = {location => '森の入り口', inventory => []};

    ok $handler->can_handle($context,  '北'),   '北を処理可能';
    ok !$handler->can_handle($context, '調べる'), '調べるは処理不可';

    my $result = $handler->handle($context, '北');
    is $result->{handled},   1,    '処理完了';
    is $context->{location}, '小道', '場所移動';

    $result = $handler->handle($context, '西');
    is $context->{location}, '小道', '無効な方向では移動しない';
    like $result->{message}, qr/進めない/, 'エラーメッセージ';
};

subtest 'ExamineHandler' => sub {
    my $handler = ExamineHandler->new;
    my $context = {location => '古い小屋', inventory => []};

    ok $handler->can_handle($context, '調べる'), '調べるを処理可能';

    my $result = $handler->handle($context, '調べる');
    is scalar(@{$context->{inventory}}), 1,      'アイテム追加';
    is $context->{inventory}[0],         '古びた鍵', '鍵を取得';

    # 二度目は取得なし
    $result = $handler->handle($context, '調べる');
    like $result->{message}, qr/何もない/, '既に取得済み';
};

subtest 'ハンドラチェーン' => sub {
    my $move    = MoveHandler->new;
    my $examine = ExamineHandler->new;
    my $help    = HelpHandler->new;

    $move->set_next($examine)->set_next($help);

    my $context = {location => '森の入り口', inventory => []};

    # 移動コマンド
    my $result = $move->process($context, '北');
    is $context->{location}, '小道', 'チェーン経由で移動';

    # 調べるコマンド
    $context->{location} = '古い小屋';
    $result = $move->process($context, '調べる');
    ok grep { $_ eq '古びた鍵' } @{$context->{inventory}}, 'チェーン経由で調べる';

    # ヘルプコマンド
    $result = $move->process($context, 'ヘルプ');
    like $result->{message}, qr/コマンド/, 'チェーン経由でヘルプ';

    # 未知のコマンド
    $result = $move->process($context, '踊る');
    is $result->{handled}, 0, '処理不可';
};

done_testing;

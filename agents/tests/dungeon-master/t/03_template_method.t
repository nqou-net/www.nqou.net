#!/usr/bin/env perl
use v5.34;
use strict;
use feature "signatures";
no warnings "experimental::signatures";
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Capture::Tiny qw(capture);

# Test: Template Method Pattern (Chapter 4)
subtest '第4章: Template Methodパターン' => sub {
    my ($stdout, $stderr, $exit) = capture {
        system($^X, "$FindBin::Bin/../lib/04_template_method.pl");
    };

    is($exit, 0, 'スクリプトが正常終了');

    # Template Method: enter -> _on_enter -> _run_event -> _give_reward -> _on_exit
    # BattleRoomの報酬（経験値）が出力されていることを確認
    like($stdout, qr/経験値.*を獲得/, 'BattleRoom報酬（経験値）');

    # TreasureRoomの報酬（アイテム）が出力されていることを確認
    like($stdout, qr/を手に入れた/, 'TreasureRoom報酬（アイテム）');

    # TrapRoomの罠イベントが出力されていることを確認
    like($stdout, qr/罠だ！/,      'TrapRoomイベント（罠）');
    like($stdout, qr/ダメージを受けた/, 'TrapRoomダメージ');

    # 共通の処理フロー確認
    my $count = () = $stdout =~ /部屋をクリアした/g;
    is($count, 3, '3部屋分の共通退室処理');
};

done_testing;

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

# Test: Integrated DungeonMaster (Chapter 6)
subtest '第6章: 統合版ダンジョンマスター' => sub {
    my ($stdout, $stderr, $exit) = capture {
        system($^X, "$FindBin::Bin/../lib/06_dungeon_master.pl");
    };

    is($exit, 0, 'スクリプトが正常終了');

    # ダンジョンマスターのタイトル表示
    like($stdout, qr/ダンジョンマスター/, 'タイトル表示');
    like($stdout, qr/難易度: ノーマル/, '難易度表示');

    # 5層ダンジョン
    like($stdout, qr/第1層/, '第1層');
    like($stdout, qr/第5層/, '第5層');

    # 絵文字付きイベント
    like($stdout, qr/🗡️|📦|⚠️/, '絵文字付きイベント');

    # クリアメッセージ
    like($stdout, qr/ダンジョン踏破おめでとう/, 'クリアメッセージ');
};

# Test: Extension (Chapter 7)
subtest '第7章: 拡張版（ShopRoom + Nightmare）' => sub {
    my ($stdout, $stderr, $exit) = capture {
        system($^X, "$FindBin::Bin/../lib/07_extension.pl");
    };

    is($exit, 0, 'スクリプトが正常終了');

    # 悪夢モード
    like($stdout, qr/悪夢のダンジョン/, '悪夢モードタイトル');

    # ShopRoom（新しい部屋タイプ）
    like($stdout, qr/【旅の商人】/,   'ShopRoom追加');
    like($stdout, qr/いらっしゃい/,   '商人セリフ');
    like($stdout, qr/商品リスト/,    '商品リスト表示');
    like($stdout, qr/回復薬.*50G/, '商品価格表示');
    like($stdout, qr/商人と別れた/,   'ShopRoom退室');

    # NightmareDifficulty（モンスター強さ5倍=50）
    like($stdout, qr/強さ: 50/, 'Nightmareモンスター強さ（5倍=50）');
};

done_testing;

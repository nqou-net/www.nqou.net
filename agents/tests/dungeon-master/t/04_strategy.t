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

# Test: Strategy Pattern (Chapter 5)
subtest '第5章: Strategyパターン（難易度）' => sub {
    my ($stdout, $stderr, $exit) = capture {
        system($^X, "$FindBin::Bin/../lib/05_strategy.pl");
    };

    is($exit, 0, 'スクリプトが正常終了');

    # ハードモードで実行されていることを確認
    like($stdout, qr/ダンジョン探索開始（ハード）/, 'ハードモード選択確認');
    like($stdout, qr/ハードモード/,         '難易度表示');

    # モンスターの強さが表示されていることを確認
    like($stdout, qr/強さ: \d+/, 'モンスター強さ表示');

    # ハードモードの特徴（強さ2倍 = 20）
    like($stdout, qr/強さ: 20/, 'ハードモンスター強さ（2倍=20）');

    # 罠のダメージ
    like($stdout, qr/\d+ ダメージを受けた/, '罠ダメージ表示');
};

done_testing;

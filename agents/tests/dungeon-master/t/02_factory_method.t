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

# Test: Factory Method Pattern (Chapter 3)
subtest '第3章: Factory Methodパターン' => sub {
    my ($stdout, $stderr, $exit) = capture {
        system($^X, "$FindBin::Bin/../lib/03_factory_method.pl");
    };

    is($exit, 0, 'スクリプトが正常終了');
    like($stdout, qr/ダンジョン探索開始/, '開始メッセージ出力');

    # 各部屋タイプが生成されていることを確認
    like($stdout, qr/【戦闘の間】/, 'BattleRoom生成');
    like($stdout, qr/【宝物庫】/,  'TreasureRoom生成');
    like($stdout, qr/【罠の間】/,  'TrapRoom生成');

    # 5部屋分あることを確認
    my $count = () = $stdout =~ /部屋をクリアした/g;
    is($count, 5, '5部屋分のクリアメッセージ');
};

done_testing;

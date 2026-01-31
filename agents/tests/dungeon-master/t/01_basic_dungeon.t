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

# Test 1: Simple BattleRoom (Chapter 1)
subtest '第1章: BattleRoomの基本動作' => sub {
    my ($stdout, $stderr, $exit) = capture {
        system($^X, "$FindBin::Bin/../lib/01_simple_dungeon.pl");
    };

    is($exit, 0, 'スクリプトが正常終了');
    like($stdout, qr/ダンジョン探索開始/,   '開始メッセージ出力');
    like($stdout, qr/【戦闘の間】に入った！/, '入室メッセージ出力');
    like($stdout, qr/が現れた！/,       'モンスター出現');
    like($stdout, qr/を倒した！/,       'モンスター撃破');
    like($stdout, qr/部屋をクリアした/,    'クリアメッセージ');
    like($stdout, qr/探索終了/,        '終了メッセージ');
};

# Test 2: if/else version (Chapter 2)
subtest '第2章: if/else版の複数部屋' => sub {
    my ($stdout, $stderr, $exit) = capture {
        system($^X, "$FindBin::Bin/../lib/02_messy_dungeon.pl");
    };

    is($exit, 0, 'スクリプトが正常終了');
    like($stdout, qr/【戦闘の間】/, 'battle部屋あり');
    like($stdout, qr/【宝物庫】/,  'treasure部屋あり');
    like($stdout, qr/【罠の間】/,  'trap部屋あり');

    # 5部屋分あることを確認
    my $count = () = $stdout =~ /部屋をクリアした/g;
    is($count, 5, '5部屋クリア');
};

done_testing;

#!/usr/bin/env perl
use v5.36;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

# 第1回のコード例をテスト

subtest 'simple_reply.pl - 破綻版' => sub {
    require 'simple_reply.pl';

    my $bot = SimpleBot->new;

    # すべてのメッセージに同じパターンで応答
    my $res1 = $bot->handle_message("/hello");
    like($res1, qr/Hello! I received:/, 'responds to any message');

    my $res2 = $bot->handle_message("random text");
    like($res2, qr/Hello! I received:/, 'responds the same way to random text');
};

subtest 'hello_command.pl - 改善版' => sub {
    require 'hello_command.pl';

    my $bot = HelloBot->new;

    # /helloコマンドに応答
    my $res1 = $bot->handle_message("/hello");
    like($res1, qr/Hello, Guest!/, 'responds to /hello');

    my $res2 = $bot->handle_message("/hello World");
    like($res2, qr/Hello, World!/, 'responds with name');

    # コマンド以外は無視
    my $res3 = $bot->handle_message("random text");
    is($res3, undef, 'ignores non-command messages');
};

done_testing;

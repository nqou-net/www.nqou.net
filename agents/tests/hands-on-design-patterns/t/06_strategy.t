#!/usr/bin/env perl
use v5.36;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

# 第6回のコード例をテスト

subtest 'strategy_response.pl - Strategyパターン' => sub {
    require 'strategy_response.pl';

    my $bot = StrategyBot->new;

    # デフォルトはFriendly
    like($bot->handle_message("/hello World"), qr/👋/, 'friendly style has emoji');

    # Formalに切り替え
    $bot->set_style('formal');
    like($bot->handle_message("/hello World"), qr/Good day/, 'formal style is polite');

    # Technicalに切り替え
    $bot->set_style('technical');
    like($bot->handle_message("/hello World"), qr/\[INFO\]/, 'technical style has prefix');
};

done_testing;

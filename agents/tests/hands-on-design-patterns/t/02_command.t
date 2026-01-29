#!/usr/bin/env perl
use v5.36;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

# 第2回のコード例をテスト

subtest 'command_if_else.pl - 破綻版' => sub {
    require 'command_if_else.pl';

    my $bot = IfElseBot->new;

    like($bot->handle_message("/hello World"), qr/Hello, World!/,      'hello command works');
    like($bot->handle_message("/help"),        qr/Available commands/, 'help command works');
    like($bot->handle_message("/status"),      qr/Bot status/,         'status command works');
    ok(defined $bot->handle_message("/joke"), 'joke command works');
};

subtest 'command_object.pl - 改善版' => sub {
    require 'command_object.pl';

    my $bot = CommandBot->new;
    $bot->register(HelloCommand->new)->register(HelpCommand->new)->register(StatusCommand->new)->register(JokeCommand->new);

    like($bot->handle_message("/hello World"), qr/Hello, World!/,   'hello command works');
    like($bot->handle_message("/help"),        qr/\/hello/,         'help lists commands');
    like($bot->handle_message("/status"),      qr/online/,          'status command works');
    like($bot->handle_message("/unknown"),     qr/Unknown command/, 'unknown command handled');
};

done_testing;

#!/usr/bin/env perl
use v5.36;
use warnings;

# 第2回: コマンドを増やす〜/help, /status, /joke
# コード例1: command_if_else.pl（破綻版）
# if-elseでコマンドを分岐 - コマンドが増えると破綻する

package IfElseBot {
    use Moo;

    has 'status' => (is => 'rw', default => 'online');
    has 'jokes' => (
        is      => 'ro',
        default => sub {
            [
                "Why do programmers prefer dark mode? Because light attracts bugs!",
                "There are only 10 types of people: those who understand binary and those who don't.",
                "A SQL query walks into a bar, walks up to two tables and asks... 'Can I join you?'",
            ]
        }
    );

    sub handle_message ($self, $message) {

        # 問題: コマンドが増えるとif-elseが無限に増える
        if ($message =~ m{^/hello\s*(.*)$}) {
            my $name = $1 || 'Guest';
            return "Hello, $name!";
        }
        elsif ($message =~ m{^/help$}) {
            return "Available commands: /hello, /help, /status, /joke";
        }
        elsif ($message =~ m{^/status$}) {
            return "Bot status: " . $self->status;
        }
        elsif ($message =~ m{^/joke$}) {
            my $jokes = $self->jokes;
            return $jokes->[rand @$jokes];
        }

        # 新しいコマンドを追加するたびにここにelsifを追加...
        # /weather, /remind, /translate, /meme, /quote, etc...
        # このメソッドはどんどん肥大化していく...

        return undef;
    }
}

# メイン処理
sub main {
    my $bot = IfElseBot->new;

    my @messages = (
        "/hello",
        "/help",
        "/status",
        "/joke",
        "/unknown",    # 未実装
    );

    for my $msg (@messages) {
        my $response = $bot->handle_message($msg);
        say "User: $msg";
        say "Bot: " . ($response // "(no response)");
        say "---";
    }

    # 問題点:
    # - handle_messageが巨大化する（100個のコマンド = 100個のelsif）
    # - 新しいコマンドを追加するたびにこのファイルを修正
    # - コマンドごとのロジックがバラバラに散らばる
    # - テストが困難（全体をテストしないといけない）
}

main() unless caller;

1;

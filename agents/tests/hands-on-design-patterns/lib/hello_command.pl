#!/usr/bin/env perl
use v5.36;
use warnings;

# 第1回: 執事Botの誕生〜最初の挨拶
# コード例2: hello_command.pl（改善版）
# /helloコマンドに応答する - コマンド解析の第一歩

package HelloBot {
    use Moo;

    sub handle_message ($self, $message) {

        # コマンドかどうかを判定
        if ($message =~ m{^/hello\s*(.*)$}) {
            my $name = $1 || 'Guest';
            return "Hello, $name! Welcome to Butler Bot!";
        }

        # コマンド以外は無視（またはデフォルト応答）
        return undef;    # 応答しない
    }
}

# メイン処理
sub main {
    my $bot = HelloBot->new;

    # テスト用メッセージ
    my @messages = (
        "/hello",
        "/hello World",
        "/hello Perl Developer",
        "こんにちは",    # コマンドではないので無視される
        "/help",    # 未実装コマンドなので無視される
    );

    for my $msg (@messages) {
        my $response = $bot->handle_message($msg);
        say "User: $msg";
        if (defined $response) {
            say "Bot: $response";
        }
        else {
            say "Bot: (no response)";
        }
        say "---";
    }

    # 改善点:
    # - コマンドを識別できるようになった
    # - 引数も受け取れる
    #
    # 次の課題:
    # - 他のコマンド（/help, /status等）も追加したい
    # - コマンドが増えるとif-elseが増える...
}

main() unless caller;

1;

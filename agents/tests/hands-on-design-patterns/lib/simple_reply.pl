#!/usr/bin/env perl
use v5.36;
use warnings;

# 第1回: 執事Botの誕生〜最初の挨拶
# コード例1: simple_reply.pl（破綻版）
# すべてのメッセージに応答する - 問題点を体験するためのコード

package SimpleBot {
    use Moo;

    sub handle_message ($self, $message) {

        # すべてのメッセージに「Hello!」と返す
        # 問題: どんなメッセージにも同じ応答をしてしまう
        return "Hello! I received: $message";
    }
}

# メイン処理
sub main {
    my $bot = SimpleBot->new;

    # テスト用メッセージ
    my @messages = ("こんにちは", "/help", "/status", "今日の天気は？", "/joke",);

    for my $msg (@messages) {
        my $response = $bot->handle_message($msg);
        say "User: $msg";
        say "Bot: $response";
        say "---";
    }

    # 問題点:
    # - すべてのメッセージに同じ応答
    # - コマンド（/help, /status等）を区別できない
    # - 機能を追加するとhandle_messageが肥大化する
}

main() unless caller;

1;

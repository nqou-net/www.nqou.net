package HelpHandler;
use v5.36;
use warnings;
use Moo;

with 'CommandHandler';

# ヘルプコマンドを処理するハンドラ

sub can_handle($self, $context, $command) {
    return $command eq 'ヘルプ';
}

sub handle($self, $context, $command) {
    return {
        handled => 1,
        message => 'コマンド: 北, 南, 東, 西, 調べる, 話す, 使う [アイテム], 持ち物, ヘルプ, 終了',
    };
}

1;

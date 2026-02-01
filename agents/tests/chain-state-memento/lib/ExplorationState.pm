package ExplorationState;
use v5.36;
use warnings;
use Moo;

with 'GameState';

# 探索モード: 移動・調べる・話すなどが可能

sub name($self) {'探索'}

sub available_commands($self) {
    return ['北', '南', '東', '西', '調べる', '話す', '使う', '持ち物', 'ヘルプ'];
}

sub on_enter($self, $context) {
    return '探索モードに入った。';
}

sub process_command($self, $context, $command) {

    # 探索モード固有のコマンド処理
    # 実際の処理はハンドラチェーンに委譲
    return undef;    # ハンドラチェーンに任せる
}

1;

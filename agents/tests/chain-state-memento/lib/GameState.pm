package GameState;
use v5.36;
use warnings;
use Moo::Role;

# State パターン: ゲームモードの基底ロール
# 探索/戦闘/イベントなどのモードによって振る舞いを変える

requires 'name';
requires 'available_commands';
requires 'process_command';
requires 'on_enter';

sub enter($self, $context) {
    return $self->on_enter($context);
}

1;

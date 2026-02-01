package CommandHandler;
use v5.36;
use warnings;
use Moo::Role;

# Chain of Responsibility: ハンドラの基底ロール
# 各ハンドラは次のハンドラへの参照を持ち、処理できなければ次へ渡す

has next_handler => (
    is        => 'rw',
    predicate => 'has_next',
);

requires 'can_handle';
requires 'handle';

sub set_next($self, $handler) {
    $self->next_handler($handler);
    return $handler;    # チェーン構築のため自身を返す
}

sub process($self, $context, $command) {
    if ($self->can_handle($context, $command)) {
        return $self->handle($context, $command);
    }

    if ($self->has_next) {
        return $self->next_handler->process($context, $command);
    }

    return {handled => 0, message => 'そのコマンドは分からない。「ヘルプ」で確認しよう。'};
}

1;

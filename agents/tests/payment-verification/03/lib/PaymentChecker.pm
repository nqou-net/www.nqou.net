# PaymentChecker.pm
# Perl v5.36+, Moo

package PaymentChecker;
use v5.36;
use Moo;

# 次のチェッカーへの参照
has 'next_handler' => (
    is        => 'rw',
    predicate => 'has_next_handler',
);

# 次のチェッカーを設定して、チェーンを構築
sub set_next ($self, $handler) {
    $self->next_handler($handler);
    return $handler;  # チェーン構築を続けられるように
}

# 審査を実行（サブクラスでオーバーライド）
sub check ($self, $request) {
    # デフォルトは次のハンドラに委譲
    return $self->pass_to_next($request);
}

# 次のハンドラに処理を委譲
sub pass_to_next ($self, $request) {
    if ($self->has_next_handler) {
        return $self->next_handler->check($request);
    }
    # チェーンの最後に到達 = 全チェック通過
    return { ok => 1 };
}

1;

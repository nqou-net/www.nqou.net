#!/usr/bin/env perl
# 第5回 コード例1: ポーリング実装 - 問題を体感する
use v5.36;
use Moo;
use namespace::clean;

package Message {
    use Moo;
    use namespace::clean;
    has 'sender'    => (is => 'ro', required => 1);
    has 'recipient' => (is => 'ro', required => 1);
    has 'body'      => (is => 'ro', required => 1);
    has 'timestamp' => (is => 'ro', default  => sub {time});
}

package MessageBox {
    use Moo;
    use namespace::clean;
    has 'owner'    => (is => 'ro', required => 1);
    has 'messages' => (is => 'rw', default  => sub { [] });

    sub receive($self, $msg) { push $self->messages->@*, $msg }
    sub count($self)         { scalar $self->messages->@* }
    sub get_all($self)       { $self->messages->@* }
}

# 問題: ポーリングでメッセージをチェックする
package MessagePoller {
    use Moo;
    use namespace::clean;

    has 'box'        => (is => 'ro', required => 1);
    has 'last_count' => (is => 'rw', default  => 0);

    sub check_for_new($self) {
        my $current_count = $self->box->count;
        if ($current_count > $self->last_count) {
            my $new_count = $current_count - $self->last_count;
            $self->last_count($current_count);
            return $new_count;
        }
        return 0;
    }
}

# デモ
sub demo {
    say "=== 第5回: ポーリングの問題点 ===\n";

    my $box    = MessageBox->new(owner => 'Bob');
    my $poller = MessagePoller->new(box => $box);

    say "シミュレーション: 定期的にチェック";

    # ループでポーリング（非効率）
    for my $i (1 .. 5) {
        say "\n--- チェック $i 回目 ---";

        # ランダムでメッセージが届く
        if (rand() > 0.5) {
            $box->receive(
                Message->new(
                    sender    => 'Alice',
                    recipient => 'Bob',
                    body      => "Message $i"
                )
            );
            say "  (メッセージが届いた)";
        }

        my $new = $poller->check_for_new;
        if ($new > 0) {
            say "  → 新着 $new 件発見！";
        }
        else {
            say "  → 新着なし（無駄なチェック）";
        }
    }

    say "\n問題点:";
    say "- 定期的にチェックが必要 → CPU/リソースの無駄";
    say "- チェック間隔が長い → 通知が遅れる";
    say "- チェック間隔が短い → 負荷が増える";
    say "- メッセージの到着を知っているのはMessageBoxだけ";
}

demo() unless caller;

1;

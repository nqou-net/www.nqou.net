use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

# === Before: 防衛的プログラミング（Defensive Programming） ===
# 通知システム。ユーザーごとに通知先が異なり、
# 「通知不要」のユーザーは notifier が undef。
# あらゆる箇所に defined チェックが増殖している。

package EmailNotifier {
    use Moo;
    has address => ( is => 'ro', required => 1 );
    has sent => ( is => 'rw', default => sub { [] } );

    sub send ($self, $message) {
        push $self->sent->@*, { to => $self->address, body => $message };
        return 1;
    }
}

package SlackNotifier {
    use Moo;
    has channel => ( is => 'ro', required => 1 );
    has sent => ( is => 'rw', default => sub { [] } );

    sub send ($self, $message) {
        push $self->sent->@*, { channel => $self->channel, body => $message };
        return 1;
    }
}

package Logger {
    use Moo;
    has logs => ( is => 'rw', default => sub { [] } );

    sub log ($self, $level, $message) {
        push $self->logs->@*, { level => $level, message => $message };
        return 1;
    }
}

# --- 問題のクラス: 防衛的プログラミングの温床 ---
package NotificationService {
    use Moo;
    use Carp qw( croak );

    # すべてオプショナル — undef の可能性がある
    has email_notifier => ( is => 'ro' );
    has slack_notifier => ( is => 'ro' );
    has logger         => ( is => 'ro' );

    sub notify_order_placed ($self, $order_id, $customer) {
        my $msg = "注文 #${order_id} が ${customer} から入りました";

        # ↓ 毎回同じ防衛パターンの繰り返し！
        if (defined $self->email_notifier) {
            $self->email_notifier->send($msg);
        }
        if (defined $self->slack_notifier) {
            $self->slack_notifier->send($msg);
        }
        if (defined $self->logger) {
            $self->logger->log('info', $msg);
        }
    }

    sub notify_order_shipped ($self, $order_id) {
        my $msg = "注文 #${order_id} が発送されました";

        # ↓ また同じ defined チェック！
        if (defined $self->email_notifier) {
            $self->email_notifier->send($msg);
        }
        if (defined $self->slack_notifier) {
            $self->slack_notifier->send($msg);
        }
        if (defined $self->logger) {
            $self->logger->log('info', $msg);
        }
    }

    sub notify_order_cancelled ($self, $order_id, $reason) {
        my $msg = "注文 #${order_id} がキャンセルされました: ${reason}";

        # ↓ さらにまた同じ防衛線！
        if (defined $self->email_notifier) {
            $self->email_notifier->send($msg);
        }
        if (defined $self->slack_notifier) {
            $self->slack_notifier->send($msg);
        }
        if (defined $self->logger) {
            $self->logger->log('warn', $msg);
        }
    }

    sub notify_payment_failed ($self, $order_id, $error) {
        my $msg = "注文 #${order_id} の決済に失敗しました: ${error}";

        if (defined $self->email_notifier) {
            $self->email_notifier->send($msg);
        }
        if (defined $self->slack_notifier) {
            $self->slack_notifier->send($msg);
        }
        if (defined $self->logger) {
            $self->logger->log('error', $msg);
        }
    }
}

1;

use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

# === After: Null Object パターン ===
# 「何もしない」オブジェクトを用意することで、
# defined チェックを完全に排除する。

# --- Notifier ロール（インターフェース）---
package Notifier {
    use Moo::Role;
    requires 'send';
}

# --- 本物の通知実装 ---
package EmailNotifier {
    use Moo;
    with 'Notifier';

    has address => ( is => 'ro', required => 1 );
    has sent => ( is => 'rw', default => sub { [] } );

    sub send ($self, $message) {
        push $self->sent->@*, { to => $self->address, body => $message };
        return 1;
    }
}

package SlackNotifier {
    use Moo;
    with 'Notifier';

    has channel => ( is => 'ro', required => 1 );
    has sent => ( is => 'rw', default => sub { [] } );

    sub send ($self, $message) {
        push $self->sent->@*, { channel => $self->channel, body => $message };
        return 1;
    }
}

# --- Null Object: 何もしないが、同じインターフェースに応答する ---
package NullNotifier {
    use Moo;
    with 'Notifier';

    sub send ($self, $message) {
        # 何もしない。それが仕事。
        return 1;
    }
}

# --- Logger ロール ---
package LoggerRole {
    use Moo::Role;
    requires 'log';
}

package Logger {
    use Moo;
    with 'LoggerRole';

    has logs => ( is => 'rw', default => sub { [] } );

    sub log ($self, $level, $message) {
        push $self->logs->@*, { level => $level, message => $message };
        return 1;
    }
}

# --- NullLogger: ログも何もしない ---
package NullLogger {
    use Moo;
    with 'LoggerRole';

    sub log ($self, $level, $message) {
        # 何もしない。
        return 1;
    }
}

# --- 解決後の NotificationService ---
# defined チェックが完全に消滅！
package NotificationService {
    use Moo;

    # デフォルトで Null Object を注入 — undef は存在しない
    has email_notifier => (
        is      => 'ro',
        default => sub { NullNotifier->new },
    );
    has slack_notifier => (
        is      => 'ro',
        default => sub { NullNotifier->new },
    );
    has logger => (
        is      => 'ro',
        default => sub { NullLogger->new },
    );

    sub notify_order_placed ($self, $order_id, $customer) {
        my $msg = "注文 #${order_id} が ${customer} から入りました";
        # ↓ defined チェック不要！ 全員が send/log に応答する
        $self->email_notifier->send($msg);
        $self->slack_notifier->send($msg);
        $self->logger->log('info', $msg);
    }

    sub notify_order_shipped ($self, $order_id) {
        my $msg = "注文 #${order_id} が発送されました";
        $self->email_notifier->send($msg);
        $self->slack_notifier->send($msg);
        $self->logger->log('info', $msg);
    }

    sub notify_order_cancelled ($self, $order_id, $reason) {
        my $msg = "注文 #${order_id} がキャンセルされました: ${reason}";
        $self->email_notifier->send($msg);
        $self->slack_notifier->send($msg);
        $self->logger->log('warn', $msg);
    }

    sub notify_payment_failed ($self, $order_id, $error) {
        my $msg = "注文 #${order_id} の決済に失敗しました: ${error}";
        $self->email_notifier->send($msg);
        $self->slack_notifier->send($msg);
        $self->logger->log('error', $msg);
    }
}

# --- 新チャネル追加も簡単: SmsNotifier ---
package SmsNotifier {
    use Moo;
    with 'Notifier';

    has phone => ( is => 'ro', required => 1 );
    has sent  => ( is => 'rw', default => sub { [] } );

    sub send ($self, $message) {
        push $self->sent->@*, { phone => $self->phone, body => $message };
        return 1;
    }
}

1;

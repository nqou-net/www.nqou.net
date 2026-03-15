#!/usr/bin/env perl
use v5.36;
use warnings;
use utf8;

# --- 通知機能の各クラス ---
package EmailNotifier {
    use Moo;
    sub send ($self, $message) {
        return "Email sent: $message";
    }
}

package SmsNotifier {
    use Moo;
    sub send ($self, $message) {
        return "SMS sent: $message";
    }
}

package SlackNotifier {
    use Moo;
    sub send ($self, $message) {
        return "Slack message sent: $message";
    }
}

# --- メインロジック（問題があるクラス） ---
package OrderService {
    use Moo;
    use Carp qw(croak);

    # 決済完了処理。通知の種類を受け取る
    sub complete_order ($self, $order_id, $notification_type) {
        my $message = "Order $order_id has been completed.";
        my $notifier;

        # 【問題点】
        # 新しい通知方法が増えるたびに、この `complete_order` メソッドを修正しなければならない。
        # 使う側（OrderService）が、作り方（各Notifierの実体）を具体的に知ってしまっている。
        if ($notification_type eq 'email') {
            $notifier = EmailNotifier->new();
        } elsif ($notification_type eq 'sms') {
            $notifier = SmsNotifier->new();
        } elsif ($notification_type eq 'slack') {
            $notifier = SlackNotifier->new();
        } else {
            croak "Unknown notification type: $notification_type";
        }

        my $result = $notifier->send($message);
        return $result;
    }
}

package main {
    # スクリプトとして直接実行された場合のみ動作
    if (!caller) {
        my $service = OrderService->new();
        say $service->complete_order('12345', 'email');
        say $service->complete_order('12346', 'slack');
    }
}

1;

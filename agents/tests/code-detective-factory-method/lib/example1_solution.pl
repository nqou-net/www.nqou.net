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

# --- Factory クラス ---
package NotifierFactory {
    use Moo;
    use Carp qw(croak);

    # 生成ロジック（どの種類をどう生成するか）をここに閉じ込める
    sub create ($self, $type) {
        if ($type eq 'email') {
            return EmailNotifier->new();
        } elsif ($type eq 'sms') {
            return SmsNotifier->new();
        } elsif ($type eq 'slack') {
            return SlackNotifier->new();
        } else {
            croak "Unknown notification type: $type";
        }
    }
}

# --- メインロジック（改善されたクラス） ---
package OrderService {
    use Moo;

    # 依存性の注入(DI)を使って、利用する Factory を外部から受け取る
    has 'notifier_factory' => (
        is => 'ro',
        # default => sub { NotifierFactory->new() } のように設定しても良いが
        # テスト容易性のために必須にするか、デフォルトで実物を設定するか選べる
        required => 1,
    );

    # 決済完了処理。
    sub complete_order ($self, $order_id, $notification_type) {
        my $message = "Order $order_id has been completed.";

        # 【改善点】
        # 使う側（OrderService）は、作り方を知らなくて良い。
        # Factoryに「$notification_type の Notifier を作ってくれ」と頼むだけ。
        # 新しい通知方法が増えても、OrderService自体は修正不要になる。
        my $notifier = $self->notifier_factory->create($notification_type);

        my $result = $notifier->send($message);
        return $result;
    }
}

package main {
    # スクリプトとして直接実行された場合のみ動作
    if (!caller) {
        my $factory = NotifierFactory->new();
        my $service = OrderService->new( notifier_factory => $factory );
        say $service->complete_order('12345', 'email');
        say $service->complete_order('12346', 'slack');
    }
}

1;

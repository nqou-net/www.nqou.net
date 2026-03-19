#!/usr/bin/env perl
use v5.36;
use warnings;
use utf8;

# --- 通知システム（改善版: Decorator パターン） ---

# 共通のロール（インターフェース）
package Notifier {
    use Moo::Role;

    requires 'send';

    has recipient => ( is => 'ro', required => 1 );
}

# --- 基本の通知クラス（具象コンポーネント） ---

package EmailSender {
    use Moo;
    with 'Notifier';

    sub send ($self, $message) {
        return "[Email to " . $self->recipient . "] $message";
    }
}

package SlackSender {
    use Moo;
    with 'Notifier';

    sub send ($self, $message) {
        return "[Slack to " . $self->recipient . "] $message";
    }
}

package SmsSender {
    use Moo;
    with 'Notifier';

    sub send ($self, $message) {
        return "[SMS to " . $self->recipient . "] $message";
    }
}

# --- Decorator基底クラス ---

package NotifierDecorator {
    use Moo;
    with 'Notifier';

    has notifier => ( is => 'ro', required => 1 );

    # recipientは内部のnotifierから委譲
    has '+recipient' => ( required => 0, lazy => 1, default => sub ($self) {
        $self->notifier->recipient;
    });

    sub send ($self, $message) {
        return $self->notifier->send($message);
    }
}

# --- 具象Decorator ---

package RetryDecorator {
    use Moo;
    extends 'NotifierDecorator';

    has max_retries => ( is => 'ro', default => 3 );

    sub send ($self, $message) {
        my $result;
        for my $attempt (1 .. $self->max_retries) {
            $result = $self->notifier->send($message);
            last if $result;
        }
        return "$result (retried up to " . $self->max_retries . " times)";
    }
}

package LogDecorator {
    use Moo;
    extends 'NotifierDecorator';

    has log => ( is => 'rw', default => sub { [] } );

    sub send ($self, $message) {
        my $result = $self->notifier->send($message);
        push @{$self->log}, "LOG: $result";
        return $result;
    }
}

package FilterDecorator {
    use Moo;
    extends 'NotifierDecorator';

    has filter_word => ( is => 'ro', required => 1 );

    sub send ($self, $message) {
        if (index($message, $self->filter_word) >= 0) {
            return "[FILTERED] Message contained '" . $self->filter_word . "'";
        }
        return $self->notifier->send($message);
    }
}

package main {
    if (!caller) {
        # 【改善後】
        # Decoratorを自由に組み合わせるだけ！
        # Email + Retry + Log
        my $notifier = LogDecorator->new(
            notifier => RetryDecorator->new(
                notifier => EmailSender->new(recipient => 'user@example.com'),
            ),
        );
        say $notifier->send("サーバー障害が発生しました");
        say "Log: @{$notifier->log}";

        # SMS通知を追加したい？ SmsSenderを1つ作るだけ！
        my $sms = RetryDecorator->new(
            notifier => SmsSender->new(recipient => '090-1234-5678'),
        );
        say $sms->send("緊急アラート");
    }
}

1;

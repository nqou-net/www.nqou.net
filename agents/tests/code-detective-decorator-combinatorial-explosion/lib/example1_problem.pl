#!/usr/bin/env perl
use v5.36;
use warnings;
use utf8;

# --- 通知システム（問題版: サブクラスの組み合わせ爆発） ---

# 基底クラス
package BaseNotifier {
    use Moo;

    has recipient => ( is => 'ro', required => 1 );

    sub send ($self, $message) {
        die "send() must be overridden";
    }
}

# 基本の通知クラス
package EmailNotifier {
    use Moo;
    extends 'BaseNotifier';

    sub send ($self, $message) {
        return "[Email to " . $self->recipient . "] $message";
    }
}

package SlackNotifier {
    use Moo;
    extends 'BaseNotifier';

    sub send ($self, $message) {
        return "[Slack to " . $self->recipient . "] $message";
    }
}

# --- ここから組み合わせ爆発が始まる ---

# Email + Retry
package EmailRetryNotifier {
    use Moo;
    extends 'EmailNotifier';

    has max_retries => ( is => 'ro', default => 3 );

    sub send ($self, $message) {
        my $result;
        for my $attempt (1 .. $self->max_retries) {
            $result = $self->SUPER::send($message);
            last if $result;
        }
        return "$result (retried up to " . $self->max_retries . " times)";
    }
}

# Email + Log
package EmailLogNotifier {
    use Moo;
    extends 'EmailNotifier';

    has log => ( is => 'rw', default => sub { [] } );

    sub send ($self, $message) {
        my $result = $self->SUPER::send($message);
        push @{$self->log}, "LOG: $result";
        return $result;
    }
}

# Email + Retry + Log（リトライとログの両方が必要 → また新しいサブクラス！）
package EmailRetryLogNotifier {
    use Moo;
    extends 'EmailNotifier';

    has max_retries => ( is => 'ro', default => 3 );
    has log         => ( is => 'rw', default => sub { [] } );

    sub send ($self, $message) {
        my $result;
        for my $attempt (1 .. $self->max_retries) {
            $result = $self->SUPER::send($message);
            last if $result;
        }
        $result = "$result (retried up to " . $self->max_retries . " times)";
        push @{$self->log}, "LOG: $result";
        return $result;
    }
}

# Slack + Retry（Emailと同じリトライロジックをコピペ！）
package SlackRetryNotifier {
    use Moo;
    extends 'SlackNotifier';

    has max_retries => ( is => 'ro', default => 3 );

    sub send ($self, $message) {
        my $result;
        for my $attempt (1 .. $self->max_retries) {
            $result = $self->SUPER::send($message);
            last if $result;
        }
        return "$result (retried up to " . $self->max_retries . " times)";
    }
}

# Slack + Log（またコピペ！）
package SlackLogNotifier {
    use Moo;
    extends 'SlackNotifier';

    has log => ( is => 'rw', default => sub { [] } );

    sub send ($self, $message) {
        my $result = $self->SUPER::send($message);
        push @{$self->log}, "LOG: $result";
        return $result;
    }
}

# Slack + Retry + Log（もはやカオス）
package SlackRetryLogNotifier {
    use Moo;
    extends 'SlackNotifier';

    has max_retries => ( is => 'ro', default => 3 );
    has log         => ( is => 'rw', default => sub { [] } );

    sub send ($self, $message) {
        my $result;
        for my $attempt (1 .. $self->max_retries) {
            $result = $self->SUPER::send($message);
            last if $result;
        }
        $result = "$result (retried up to " . $self->max_retries . " times)";
        push @{$self->log}, "LOG: $result";
        return $result;
    }
}

package main {
    if (!caller) {
        # 【問題点】
        # 2つの通知先 × 3つの機能(Retry, Log, Retry+Log) = 6つのサブクラス
        # ここにSMS通知を追加すると → さらに4クラス追加で合計10クラス
        # Filter機能を追加すると → 2^4 × 通知先数 = ...もう数えたくない
        my $notifier = EmailRetryLogNotifier->new(recipient => 'user@example.com');
        say $notifier->send("サーバー障害が発生しました");
    }
}

1;

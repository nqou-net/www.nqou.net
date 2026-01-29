#!/usr/bin/env perl
use v5.36;
use warnings;

# 第8回: 執事の業務日報〜コマンド実行ログ
# コード例2: observer_audit.pl（改善版）
# Observerパターンで複数の監査システムに通知

# ===== イベント =====
package CommandEvent {
    use Moo;

    has 'user_id'   => (is => 'ro', required => 1);
    has 'command'   => (is => 'ro', required => 1);
    has 'args'      => (is => 'ro', default  => '');
    has 'result'    => (is => 'ro');
    has 'timestamp' => (is => 'ro', default => sub {time});
}

# ===== Observer Role =====
package Observer {
    use Moo::Role;
    requires 'update';
}

# ===== 各種Observer実装 =====
package LogObserver {
    use Moo;
    with 'Observer';

    use Time::Piece;

    sub update ($self, $event) {
        my $time = localtime($event->timestamp)->strftime('%Y-%m-%d %H:%M:%S');
        say "[LOG][$time] User: @{[$event->user_id]}, Command: /@{[$event->command]}, Args: @{[$event->args]}";
    }
}

package MetricsObserver {
    use Moo;
    with 'Observer';

    has 'counters' => (is => 'ro', default => sub { {} });

    sub update ($self, $event) {
        my $cmd = $event->command;
        $self->counters->{$cmd}++;
        say "[METRICS] Command /$cmd executed (total: @{[$self->counters->{$cmd}]})";
    }

    sub report ($self) {
        return {%{$self->counters}};
    }
}

package SecurityObserver {
    use Moo;
    with 'Observer';

    has 'suspicious_patterns' => (
        is      => 'ro',
        default => sub {
            [qr/admin/i, qr/delete/i, qr/drop/i]
        }
    );

    sub update ($self, $event) {
        my $full_command = $event->command . ' ' . $event->args;

        for my $pattern (@{$self->suspicious_patterns}) {
            if ($full_command =~ $pattern) {
                say "[SECURITY] ⚠️ Suspicious activity detected!";
                say "    User: @{[$event->user_id]}";
                say "    Command: /@{[$full_command]}";
                say "    Pattern matched: $pattern";
                return;
            }
        }
    }
}

package SlackObserver {
    use Moo;
    with 'Observer';

    has 'channel' => (is => 'ro', default => '#bot-logs');

    sub update ($self, $event) {

        # 実際にはWebhookでSlackに送信
        say "[SLACK -> @{[$self->channel]}] @{[$event->user_id]} executed /@{[$event->command]}";
    }
}

# ===== Subject（通知元）=====
package Subject {
    use Moo::Role;

    has 'observers' => (is => 'ro', default => sub { [] });

    sub attach ($self, $observer) {
        push @{$self->observers}, $observer;
        return $self;
    }

    sub detach ($self, $observer) {
        @{$self->observers} = grep { $_ != $observer } @{$self->observers};
        return $self;
    }

    sub notify ($self, $event) {
        for my $observer (@{$self->observers}) {
            $observer->update($event);
        }
    }
}

# ===== コマンド =====
package Command {
    use Moo::Role;
    requires 'execute';
}

package HelloCommand {
    use Moo;
    with 'Command';
    sub execute ($self, $args, $ctx) { "Hello, " . ($args || 'Guest') . "!" }
}

package HelpCommand {
    use Moo;
    with 'Command';
    sub execute ($self, $args, $ctx) {"Available commands: /hello, /help, /status, /admin"}
}

package StatusCommand {
    use Moo;
    with 'Command';
    sub execute ($self, $args, $ctx) {"Bot status: online"}
}

package AdminCommand {
    use Moo;
    with 'Command';
    sub execute ($self, $args, $ctx) {"Admin panel: [restricted]"}
}

# ===== Bot本体 =====
package ObserverBot {
    use Moo;
    with 'Subject';

    has 'commands' => (is => 'ro', default => sub { {} });

    sub BUILD ($self, $args) {
        $self->commands->{hello}  = HelloCommand->new;
        $self->commands->{help}   = HelpCommand->new;
        $self->commands->{status} = StatusCommand->new;
        $self->commands->{admin}  = AdminCommand->new;
    }

    sub handle_message ($self, $user_id, $message) {
        if ($message =~ m{^/(\w+)\s*(.*)$}) {
            my ($cmd_name, $args) = ($1, $2);
            if (my $command = $self->commands->{$cmd_name}) {
                my $result = $command->execute($args, {});

                # イベントを作成して通知
                my $event = CommandEvent->new(
                    user_id => $user_id,
                    command => $cmd_name,
                    args    => $args,
                    result  => $result,
                );
                $self->notify($event);

                return $result;
            }
            return "Unknown command: /$cmd_name";
        }
        return undef;
    }
}

sub main {
    my $bot = ObserverBot->new;

    # 複数のObserverを登録
    my $log_observer      = LogObserver->new;
    my $metrics_observer  = MetricsObserver->new;
    my $security_observer = SecurityObserver->new;
    my $slack_observer    = SlackObserver->new(channel => '#butler-bot');

    $bot->attach($log_observer)->attach($metrics_observer)->attach($security_observer)->attach($slack_observer);

    say "=== Normal Commands ===";
    for my $msg ("/hello World", "/help", "/status") {
        say "";
        say "User [alice]: $msg";
        my $response = $bot->handle_message('alice', $msg);
        say "Bot: $response";
    }

    say "";
    say "=== Suspicious Command ===";
    say "";
    say "User [bob]: /admin delete users";
    my $response = $bot->handle_message('bob', '/admin delete users');
    say "Bot: $response";

    say "";
    say "=== Metrics Report ===";
    my $report = $metrics_observer->report;
    for my $cmd (sort keys %$report) {
        say "  /$cmd: $report->{$cmd} times";
    }

    # 改善点:
    # - 通知先はObserverとして登録するだけ
    # - 新しい通知先（Email、PagerDuty等）はObserverを追加
    # - Bot本体のコードは変更不要
    # - Observerを動的に追加・削除可能
}

main() unless caller;

1;

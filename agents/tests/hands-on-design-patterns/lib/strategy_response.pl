#!/usr/bin/env perl
use v5.36;
use warnings;

# 第6回: Botの性格を変える〜フレンドリー/フォーマル
# コード例2: strategy_response.pl（改善版）
# Strategyパターンで応答スタイルを動的に切り替え

# ===== 応答戦略Role =====
package ResponseStrategy {
    use Moo::Role;

    requires 'format_greeting';
    requires 'format_info';
    requires 'format_error';
    requires 'format_success';
}

# ===== フレンドリー戦略 =====
package FriendlyStrategy {
    use Moo;
    with 'ResponseStrategy';

    sub format_greeting ($self, $name) {
        return "Hey $name! 👋 Great to see you!";
    }

    sub format_info ($self, $message) {
        return "ℹ️ $message";
    }

    sub format_error ($self, $message) {
        return "😅 Oops! $message Don't worry, we'll figure it out!";
    }

    sub format_success ($self, $message) {
        return "🎉 Awesome! $message";
    }
}

# ===== フォーマル戦略 =====
package FormalStrategy {
    use Moo;
    with 'ResponseStrategy';

    sub format_greeting ($self, $name) {
        return "Good day, $name. Welcome to the Butler Bot service.";
    }

    sub format_info ($self, $message) {
        return "Information: $message";
    }

    sub format_error ($self, $message) {
        return "Error: $message Please contact support if the issue persists.";
    }

    sub format_success ($self, $message) {
        return "Success: $message";
    }
}

# ===== テクニカル戦略 =====
package TechnicalStrategy {
    use Moo;
    with 'ResponseStrategy';

    sub format_greeting ($self, $name) {
        return "[INFO] User '$name' connected successfully.";
    }

    sub format_info ($self, $message) {
        return "[INFO] $message";
    }

    sub format_error ($self, $message) {
        return "[ERROR] $message (errno: 0x0001)";
    }

    sub format_success ($self, $message) {
        return "[OK] $message (status: 200)";
    }
}

# ===== コマンド基底Role =====
package Command {
    use Moo::Role;
    requires 'execute';
}

# ===== 各コマンド（戦略を使用） =====
package HelloCommand {
    use Moo;
    with 'Command';

    sub execute ($self, $args, $ctx) {
        my $name     = $args || 'Guest';
        my $strategy = $ctx->{strategy};
        return $strategy->format_greeting($name);
    }
}

package HelpCommand {
    use Moo;
    with 'Command';

    sub execute ($self, $args, $ctx) {
        my $strategy = $ctx->{strategy};
        return $strategy->format_info("Available commands: /hello, /help, /status, /style");
    }
}

package StatusCommand {
    use Moo;
    with 'Command';

    sub execute ($self, $args, $ctx) {
        my $strategy = $ctx->{strategy};
        return $strategy->format_success("Bot is running normally.");
    }
}

package StyleCommand {
    use Moo;
    with 'Command';

    sub execute ($self, $args, $ctx) {
        my $strategy   = $ctx->{strategy};
        my $style_name = ref($strategy);
        $style_name =~ s/Strategy$//;
        return $strategy->format_info("Current style: $style_name");
    }
}

# ===== Bot本体 =====
package StrategyBot {
    use Moo;

    has 'commands' => (is => 'ro', default => sub { {} });
    has 'strategy' => (is => 'rw', default => sub { FriendlyStrategy->new });

    sub BUILD ($self, $args) {
        $self->commands->{hello}  = HelloCommand->new;
        $self->commands->{help}   = HelpCommand->new;
        $self->commands->{status} = StatusCommand->new;
        $self->commands->{style}  = StyleCommand->new;
    }

    sub set_style ($self, $style_name) {
        my %strategies = (
            friendly  => FriendlyStrategy->new,
            formal    => FormalStrategy->new,
            technical => TechnicalStrategy->new,
        );

        if (my $strategy = $strategies{lc $style_name}) {
            $self->strategy($strategy);
            return 1;
        }
        return 0;
    }

    sub handle_message ($self, $message) {
        if ($message =~ m{^/(\w+)\s*(.*)$}) {
            my ($cmd_name, $args) = ($1, $2);

            # スタイル切り替えコマンド
            if ($cmd_name eq 'setstyle') {
                if ($self->set_style($args)) {
                    return $self->strategy->format_success("Style changed to: $args");
                }
                return $self->strategy->format_error("Unknown style: $args");
            }

            if (my $command = $self->commands->{$cmd_name}) {
                my $context = {strategy => $self->strategy};
                return $command->execute($args, $context);
            }
            return $self->strategy->format_error("Unknown command: /$cmd_name");
        }
        return undef;
    }
}

sub main {
    my $bot = StrategyBot->new;

    say "=== Friendly Style ===";
    for my $msg ("/hello World", "/status") {
        my $response = $bot->handle_message($msg);
        say "User: $msg";
        say "Bot: $response";
    }

    say "";
    say "=== Switching to Formal Style ===";
    say "Bot: " . $bot->handle_message("/setstyle formal");

    say "";
    for my $msg ("/hello World", "/status") {
        my $response = $bot->handle_message($msg);
        say "User: $msg";
        say "Bot: $response";
    }

    say "";
    say "=== Switching to Technical Style ===";
    say "Bot: " . $bot->handle_message("/setstyle technical");

    say "";
    for my $msg ("/hello World", "/status") {
        my $response = $bot->handle_message($msg);
        say "User: $msg";
        say "Bot: $response";
    }

    # 改善点:
    # - 応答スタイルを動的に切り替え可能
    # - 新しいスタイルは新しいStrategyクラスを追加するだけ
    # - コマンドのコードは変更不要
    # - ユーザーごとに異なるスタイルも可能
}

main() unless caller;

1;

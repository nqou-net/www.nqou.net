#!/usr/bin/env perl
use v5.36;
use warnings;

# 第9回: 執事Botを完成させる〜コマンド帝国の支配者に
# コード例2: butler_final.pl（完成版）
# Command + Factory + Strategy + Observer を正しく統合

# ============================================================
# Event
# ============================================================
package CommandEvent {
    use Moo;
    has 'user_id'   => (is => 'ro', required => 1);
    has 'command'   => (is => 'ro', required => 1);
    has 'args'      => (is => 'ro', default  => '');
    has 'result'    => (is => 'ro');
    has 'timestamp' => (is => 'ro', default => sub {time});
}

# ============================================================
# Observer Pattern
# ============================================================
package Observer {
    use Moo::Role;
    requires 'update';
}

package LogObserver {
    use Moo;
    with 'Observer';
    use Time::Piece;

    sub update ($self, $event) {
        my $time = localtime($event->timestamp)->strftime('%H:%M:%S');
        say "[LOG][$time] @{[$event->user_id]}: /@{[$event->command]} @{[$event->args]}";
    }
}

package MetricsObserver {
    use Moo;
    with 'Observer';
    has 'counters' => (is => 'ro', default => sub { {} });

    sub update ($self, $event) {
        $self->counters->{$event->command}++;
    }

    sub report ($self) { $self->counters }
}

package Subject {
    use Moo::Role;
    has 'observers' => (is => 'ro', default => sub { [] });

    sub attach ($self, $observer) {
        push @{$self->observers}, $observer;
        return $self;
    }

    sub notify ($self, $event) {
        $_->update($event) for @{$self->observers};
    }
}

# ============================================================
# Strategy Pattern
# ============================================================
package ResponseStrategy {
    use Moo::Role;
    requires 'format_greeting';
    requires 'format_info';
    requires 'format_success';
    requires 'format_list';
}

package FriendlyStrategy {
    use Moo;
    with 'ResponseStrategy';

    sub format_greeting ($self, $name) {"Hey $name! 👋 Welcome!"}
    sub format_info     ($self, $msg)  {"ℹ️ $msg"}
    sub format_success  ($self, $msg)  {"✅ $msg"}

    sub format_list ($self, $title, @items) {
        return "$title:\n" . join("\n", map {"  • $_"} @items);
    }
}

package FormalStrategy {
    use Moo;
    with 'ResponseStrategy';

    sub format_greeting ($self, $name) {"Good day, $name. Welcome to Butler Bot."}
    sub format_info     ($self, $msg)  {"Information: $msg"}
    sub format_success  ($self, $msg)  {"Success: $msg"}

    sub format_list ($self, $title, @items) {
        return "$title:\n" . join("\n", map {"  - $_"} @items);
    }
}

package StrategySelector {
    use Moo;

    has 'strategies' => (
        is      => 'ro',
        default => sub {
            {
                friendly => FriendlyStrategy->new,
                formal   => FormalStrategy->new,
            }
        }
    );
    has 'default' => (is => 'ro', default => 'friendly');

    sub get ($self, $name) {
        return $self->strategies->{$name} // $self->strategies->{$self->default};
    }
}

# ============================================================
# Command Pattern
# ============================================================
package Command {
    use Moo::Role;
    requires 'run';

    sub name ($self) {
        my $class = ref($self) || $self;
        $class =~ s/.*:://;
        $class =~ s/Command$//;
        return lc($class);
    }

    sub execute ($self, $args, $ctx) {
        return $self->run($args, $ctx);
    }
}

package HelloCommand {
    use Moo;
    with 'Command';

    sub run ($self, $args, $ctx) {
        my $name = $args || 'Guest';
        return $ctx->{strategy}->format_greeting($name);
    }
}

package HelpCommand {
    use Moo;
    with 'Command';

    sub run ($self, $args, $ctx) {
        my @commands = map {"/$_"} $ctx->{factory}->list;
        return $ctx->{strategy}->format_list("Available commands", @commands);
    }
}

package StatusCommand {
    use Moo;
    with 'Command';

    sub run ($self, $args, $ctx) {
        return $ctx->{strategy}->format_success("Butler Bot is running normally.");
    }
}

package StyleCommand {
    use Moo;
    with 'Command';

    sub run ($self, $args, $ctx) {
        my $new_style = $args;
        if ($new_style && $ctx->{selector}->get($new_style)) {
            $ctx->{set_style}->($new_style);
            return $ctx->{strategy}->format_success("Style changed to: $new_style");
        }
        my @styles = sort keys %{$ctx->{selector}->strategies};
        return $ctx->{strategy}->format_list("Available styles", @styles);
    }
}

package JokeCommand {
    use Moo;
    with 'Command';

    has 'jokes' => (
        is      => 'ro',
        default => sub {
            [
                "Why do programmers prefer dark mode? Light attracts bugs!",
                "There are 10 types of people: those who understand binary and those who don't.",
                "A SQL query walks into a bar, walks up to two tables and asks... 'Can I join you?'",
            ]
        }
    );

    sub run ($self, $args, $ctx) {
        my $joke = $self->jokes->[rand @{$self->jokes}];
        return $ctx->{strategy}->format_info($joke);
    }
}

package MetricsCommand {
    use Moo;
    with 'Command';

    sub run ($self, $args, $ctx) {
        my $report = $ctx->{metrics}->report;
        my @lines  = map {"$_: $report->{$_}"} sort keys %$report;
        return $ctx->{strategy}->format_list("Command usage", @lines);
    }
}

# ============================================================
# Factory Pattern
# ============================================================
package CommandFactory {
    use Moo;
    has 'registry' => (is => 'ro', default => sub { {} });

    sub register ($self, $command) {
        my $name = $command->name;
        $self->registry->{$name} = $command;
        return $self;
    }

    sub get ($self, $name) {
        return $self->registry->{$name};
    }

    sub list ($self) {
        return sort keys %{$self->registry};
    }
}

# ============================================================
# Butler Bot (統合)
# ============================================================
package ButlerBot {
    use Moo;
    with 'Subject';

    has 'factory'  => (is => 'ro', required => 1);
    has 'selector' => (is => 'ro', default  => sub { StrategySelector->new });
    has 'users'    => (is => 'ro', default  => sub { {} });
    has 'metrics'  => (is => 'ro');

    sub get_user_style ($self, $user_id) {
        return $self->users->{$user_id}{style} // 'friendly';
    }

    sub set_user_style ($self, $user_id, $style) {
        $self->users->{$user_id} //= {};
        $self->users->{$user_id}{style} = $style;
    }

    sub handle_message ($self, $user_id, $message) {
        if ($message =~ m{^/(\w+)\s*(.*)$}) {
            my ($cmd_name, $args) = ($1, $2);

            if (my $command = $self->factory->get($cmd_name)) {
                my $style    = $self->get_user_style($user_id);
                my $strategy = $self->selector->get($style);

                my $context = {
                    factory   => $self->factory,
                    strategy  => $strategy,
                    selector  => $self->selector,
                    metrics   => $self->metrics,
                    user_id   => $user_id,
                    set_style => sub { $self->set_user_style($user_id, $_[0]) },
                };

                my $result = $command->execute($args, $context);

                # Observerに通知
                my $event = CommandEvent->new(
                    user_id => $user_id,
                    command => $cmd_name,
                    args    => $args,
                    result  => $result,
                );
                $self->notify($event);

                return $result;
            }

            my $strategy = $self->selector->get($self->get_user_style($user_id));
            return $strategy->format_info("Unknown command: /$cmd_name. Try /help");
        }
        return undef;
    }
}

# ============================================================
# Main
# ============================================================
sub main {

    # Factory: コマンドを登録
    my $factory = CommandFactory->new;
    $factory->register(HelloCommand->new)
        ->register(HelpCommand->new)
        ->register(StatusCommand->new)
        ->register(StyleCommand->new)
        ->register(JokeCommand->new)
        ->register(MetricsCommand->new);

    # Observer: 監査システムを設定
    my $log_observer     = LogObserver->new;
    my $metrics_observer = MetricsObserver->new;

    # Bot: 全てを統合
    my $bot = ButlerBot->new(
        factory => $factory,
        metrics => $metrics_observer,
    );
    $bot->attach($log_observer)->attach($metrics_observer);

    say "╔═══════════════════════════════════════════════════════════╗";
    say "║           🎩 Butler Bot - Command Empire 🏰              ║";
    say "╚═══════════════════════════════════════════════════════════╝";
    say "";

    # デモ: フレンドリーモード
    say "=== Alice (Friendly Style) ===";
    for my $msg ("/hello", "/help", "/status") {
        say "";
        say "Alice: $msg";
        my $response = $bot->handle_message('alice', $msg);
        say "Bot: $response";
    }

    # デモ: フォーマルモードに切り替え
    say "";
    say "=== Bob (Switching to Formal) ===";
    say "";
    say "Bob: /style formal";
    say "Bot: " . $bot->handle_message('bob', '/style formal');

    for my $msg ("/hello Bob", "/status") {
        say "";
        say "Bob: $msg";
        my $response = $bot->handle_message('bob', $msg);
        say "Bot: $response";
    }

    # デモ: ジョーク
    say "";
    say "=== Carol (Joke) ===";
    say "";
    say "Carol: /joke";
    say "Bot: " . $bot->handle_message('carol', '/joke');

    # デモ: メトリクス
    say "";
    say "=== Metrics Report ===";
    say "";
    say "Admin: /metrics";
    say "Bot: " . $bot->handle_message('admin', '/metrics');

    say "";
    say "═══════════════════════════════════════════════════════════";
    say "🎉 Butler Bot is complete!";
    say "";
    say "使用したパターン:";
    say "  - Command: コマンドをオブジェクトとしてカプセル化";
    say "  - Factory: コマンド名からインスタンスを生成";
    say "  - Strategy: 応答スタイルを動的に切り替え";
    say "  - Observer: コマンド実行を複数システムに通知";
}

main() unless caller;

1;

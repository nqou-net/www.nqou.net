#!/usr/bin/env perl
use v5.36;
use warnings;

# 第7回: ユーザーを見分ける〜戦略の自動選択
# コード例2: level_strategy.pl（改善版）
# ユーザーレベルに基づいてStrategyを自動選択

# ===== 応答戦略Role =====
package ResponseStrategy {
    use Moo::Role;

    requires 'format_help';
    requires 'format_status';
    requires 'format_error';
}

# ===== Beginner向け戦略 =====
package BeginnerStrategy {
    use Moo;
    with 'ResponseStrategy';

    sub format_help ($self, $commands) {
        my $basic = join(", ", grep { !/^(config|debug|admin)$/ } @$commands);
        return "Commands: $basic\n(Tip: Type /hello to greet the bot! 😊)";
    }

    sub format_status ($self, $data) {
        return "The bot is working fine! 😊";
    }

    sub format_error ($self, $error) {
        return "Oops! Something went wrong. Please try again later. 😅";
    }
}

# ===== Intermediate向け戦略 =====
package IntermediateStrategy {
    use Moo;
    with 'ResponseStrategy';

    sub format_help ($self, $commands) {
        my @filtered = grep { !/^(debug|admin)$/ } @$commands;
        return "Commands: " . join(", ", @filtered);
    }

    sub format_status ($self, $data) {
        return "Status: $data->{status} | Uptime: $data->{uptime}";
    }

    sub format_error ($self, $error) {
        return "Error: $error->{message}. Please check your input.";
    }
}

# ===== Expert向け戦略 =====
package ExpertStrategy {
    use Moo;
    with 'ResponseStrategy';

    sub format_help ($self, $commands) {
        return "Commands: " . join(", ", @$commands);
    }

    sub format_status ($self, $data) {
        return sprintf("Status: %s | Uptime: %s | Memory: %s | Load: %s", $data->{status}, $data->{uptime}, $data->{memory}, $data->{load});
    }

    sub format_error ($self, $error) {
        return sprintf("Error 0x%04X: %s at %s. Stack: %s", $error->{code}, $error->{message}, $error->{location}, $error->{stack} // 'N/A');
    }
}

# ===== 戦略セレクター =====
package StrategySelector {
    use Moo;

    has 'strategies' => (
        is      => 'ro',
        default => sub {
            {
                beginner     => BeginnerStrategy->new,
                intermediate => IntermediateStrategy->new,
                expert       => ExpertStrategy->new,
            }
        }
    );

    # ユーザーレベルから適切な戦略を選択
    sub select_for_user ($self, $user) {
        my $level = $user->{level} // 'beginner';
        return $self->strategies->{$level} // $self->strategies->{beginner};
    }
}

# ===== コマンド（シンプル）=====
package Command {
    use Moo::Role;
    requires 'execute';
}

package HelpCommand {
    use Moo;
    with 'Command';

    sub execute ($self, $args, $ctx) {
        my @commands = qw(hello help status config debug admin);
        return $ctx->{strategy}->format_help(\@commands);
    }
}

package StatusCommand {
    use Moo;
    with 'Command';

    sub execute ($self, $args, $ctx) {
        my $data = {
            status => 'OK',
            uptime => '42d 3h',
            memory => '128MB',
            load   => '0.5',
        };
        return $ctx->{strategy}->format_status($data);
    }
}

package ErrorCommand {
    use Moo;
    with 'Command';

    sub execute ($self, $args, $ctx) {
        my $error = {
            code     => 0x0042,
            message  => 'Connection timeout',
            location => 'line 128',
            stack    => 'main::connect -> Net::HTTP::request',
        };
        return $ctx->{strategy}->format_error($error);
    }
}

# ===== Bot本体 =====
package StrategyLevelBot {
    use Moo;

    has 'commands' => (is => 'ro', default => sub { {} });
    has 'users'    => (is => 'ro', default => sub { {} });
    has 'selector' => (is => 'ro', default => sub { StrategySelector->new });

    sub BUILD ($self, $args) {
        $self->commands->{help}   = HelpCommand->new;
        $self->commands->{status} = StatusCommand->new;
        $self->commands->{error}  = ErrorCommand->new;

        # ユーザー設定（モック）
        $self->users->{alice} = {level => 'beginner'};
        $self->users->{bob}   = {level => 'intermediate'};
        $self->users->{carol} = {level => 'expert'};
    }

    sub handle_message ($self, $user_id, $message) {
        if ($message =~ m{^/(\w+)\s*(.*)$}) {
            my ($cmd_name, $args) = ($1, $2);
            if (my $command = $self->commands->{$cmd_name}) {
                my $user = $self->users->{$user_id} // {level => 'beginner'};

                # 戦略を自動選択
                my $strategy = $self->selector->select_for_user($user);
                return $command->execute($args, {strategy => $strategy, user => $user});
            }
            return "Unknown command: /$cmd_name";
        }
        return undef;
    }
}

sub main {
    my $bot = StrategyLevelBot->new;

    for my $user (qw(alice bob carol)) {
        say "=== User: $user ===";
        for my $cmd (qw(/help /status /error)) {
            my $response = $bot->handle_message($user, $cmd);
            say "$cmd:";
            say "  $response";
        }
        say "";
    }

    say "改善点:";
    say "- ユーザーレベルから戦略を自動選択";
    say "- コマンドはレベル判定を行わない";
    say "- 新しいレベルは新しいStrategyを追加するだけ";
    say "- レベル判定ロジックはSelectorに集約";
}

main() unless caller;

1;

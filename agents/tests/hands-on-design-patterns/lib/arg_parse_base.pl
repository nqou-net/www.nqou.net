#!/usr/bin/env perl
use v5.36;
use warnings;

# 第3回: コマンドに引数を渡す〜/weather Tokyo
# コード例2: arg_parse_base.pl（改善版）
# 引数解析を基底クラスに集約

# ===== 引数解析用のRole =====
package ArgumentParser {
    use Moo::Role;

    # コマンド定義（サブクラスでオーバーライド）
    sub argument_spec ($self) {
        return [];    # [{ name => 'city', required => 1 }, ...]
    }

    # 引数をパースして名前付きハッシュに変換
    sub parse_args ($self, $args_string) {
        my $spec  = $self->argument_spec;
        my @parts = split /\s+/, ($args_string // '');

        my %parsed;
        my @errors;

        for my $i (0 .. $#$spec) {
            my $arg_def = $spec->[$i];
            my $name    = $arg_def->{name};
            my $value   = $parts[$i];

            if ($arg_def->{required} && !defined $value) {
                push @errors, "Missing required argument: $name";
            }

            $parsed{$name} = $value // $arg_def->{default};
        }

        return (\%parsed, \@errors);
    }

    # Usageメッセージを自動生成
    sub usage ($self) {
        my $spec = $self->argument_spec;
        my @args = map { $_->{required} ? "<$_->{name}>" : "[$_->{name}]" } @$spec;
        return "Usage: /" . $self->name . " " . join(" ", @args);
    }
}

# ===== コマンド基底Role =====
package Command {
    use Moo::Role;
    with 'ArgumentParser';

    requires 'run';    # 実際の処理

    sub name ($self) {
        my $class = ref($self) || $self;
        $class =~ s/.*:://;
        $class =~ s/Command$//;
        return lc($class);
    }

    sub execute ($self, $args, $context) {
        my ($parsed, $errors) = $self->parse_args($args);

        if (@$errors) {
            return join("\n", @$errors, $self->usage);
        }

        return $self->run($parsed, $context);
    }
}

# ===== 各コマンド実装 =====
package WeatherCommand {
    use Moo;
    with 'Command';

    has 'weather_data' => (
        is      => 'ro',
        default => sub {
            {
                tokyo => {temp => 15, condition => 'Sunny'},
                osaka => {temp => 14, condition => 'Cloudy'},
                kyoto => {temp => 13, condition => 'Rainy'},
            }
        }
    );

    sub argument_spec ($self) {
        return [{name => 'city', required => 1},];
    }

    sub run ($self, $args, $context) {
        my $city = $args->{city};
        my $data = $self->weather_data->{lc $city};

        return "Unknown city: $city" unless $data;
        return "$city: $data->{temp}°C, $data->{condition}";
    }
}

package RemindCommand {
    use Moo;
    with 'Command';

    sub argument_spec ($self) {
        return [{name => 'time', required => 1}, {name => 'message', required => 1},];
    }

    sub run ($self, $args, $context) {
        return "Reminder set: '$args->{message}' at $args->{time}";
    }
}

package TranslateCommand {
    use Moo;
    with 'Command';

    sub argument_spec ($self) {
        return [{name => 'from', required => 1}, {name => 'to', required => 1}, {name => 'text', required => 1},];
    }

    sub run ($self, $args, $context) {
        return "Translated ($args->{from} -> $args->{to}): [$args->{text}]";
    }
}

# ===== Bot本体 =====
package CommandBot {
    use Moo;
    has 'commands' => (is => 'ro', default => sub { {} });

    sub register ($self, $command) {
        $self->commands->{$command->name} = $command;
        return $self;
    }

    sub handle_message ($self, $message) {
        if ($message =~ m{^/(\w+)\s*(.*)$}) {
            my ($cmd_name, $args) = ($1, $2);
            if (my $command = $self->commands->{$cmd_name}) {
                return $command->execute($args, {});
            }
            return "Unknown command: /$cmd_name";
        }
        return undef;
    }
}

sub main {
    my $bot = CommandBot->new;
    $bot->register(WeatherCommand->new)->register(RemindCommand->new)->register(TranslateCommand->new);

    my @messages = (
        "/weather Tokyo",
        "/weather",    # 自動的にUsage表示
        "/remind 10:00 Meeting",
        "/remind",     # 自動的にUsage表示
        "/translate en ja Hello",
    );

    for my $msg (@messages) {
        my $response = $bot->handle_message($msg);
        say "User: $msg";
        say "Bot: " . ($response // "(no response)");
        say "---";
    }

    # 改善点:
    # - 引数解析ロジックは基底Roleに集約
    # - 各コマンドはargument_specを定義するだけ
    # - Usageメッセージは自動生成
    # - バリデーションも自動
}

main() unless caller;

1;

#!/usr/bin/env perl
use v5.36;
use warnings;

# 第2回: コマンドを増やす〜/help, /status, /joke
# コード例2: command_object.pl（改善版）
# Commandパターンでコマンドをオブジェクト化

# ===== コマンド基底クラス =====
package Command {
    use Moo::Role;

    requires 'execute';

    sub name ($self) {
        my $class = ref($self) || $self;
        $class =~ s/.*:://;
        $class =~ s/Command$//;
        return lc($class);
    }
}

# ===== 各コマンド実装 =====
package HelloCommand {
    use Moo;
    with 'Command';

    sub execute ($self, $args, $context) {
        my $name = $args || 'Guest';
        return "Hello, $name!";
    }
}

package HelpCommand {
    use Moo;
    with 'Command';

    sub execute ($self, $args, $context) {
        my @commands = sort keys %{$context->{commands}};
        return "Available commands: " . join(", ", map {"/$_"} @commands);
    }
}

package StatusCommand {
    use Moo;
    with 'Command';

    sub execute ($self, $args, $context) {
        return "Bot status: " . ($context->{status} // 'online');
    }
}

package JokeCommand {
    use Moo;
    with 'Command';

    has 'jokes' => (
        is      => 'ro',
        default => sub {
            [
                "Why do programmers prefer dark mode? Because light attracts bugs!",
                "There are only 10 types of people: those who understand binary and those who don't.",
                "A SQL query walks into a bar, walks up to two tables and asks... 'Can I join you?'",
            ]
        }
    );

    sub execute ($self, $args, $context) {
        my $jokes = $self->jokes;
        return $jokes->[rand @$jokes];
    }
}

# ===== Bot本体 =====
package CommandBot {
    use Moo;

    has 'commands' => (is => 'ro', default => sub { {} });
    has 'status'   => (is => 'rw', default => 'online');

    sub register ($self, $command) {
        my $name = $command->name;
        $self->commands->{$name} = $command;
        return $self;
    }

    sub handle_message ($self, $message) {

        # コマンドをパース
        if ($message =~ m{^/(\w+)\s*(.*)$}) {
            my ($cmd_name, $args) = ($1, $2);

            if (my $command = $self->commands->{$cmd_name}) {
                my $context = {
                    commands => $self->commands,
                    status   => $self->status,
                };
                return $command->execute($args, $context);
            }
            return "Unknown command: /$cmd_name";
        }
        return undef;
    }
}

# メイン処理
sub main {
    my $bot = CommandBot->new;

    # コマンドを登録
    $bot->register(HelloCommand->new)->register(HelpCommand->new)->register(StatusCommand->new)->register(JokeCommand->new);

    my @messages = ("/hello", "/hello World", "/help", "/status", "/joke", "/unknown",);

    for my $msg (@messages) {
        my $response = $bot->handle_message($msg);
        say "User: $msg";
        say "Bot: " . ($response // "(no response)");
        say "---";
    }

    # 改善点:
    # - コマンドごとに独立したクラス
    # - 新しいコマンドは新しいクラスを作って登録するだけ
    # - 既存コードを修正する必要がない（Open-Closed原則）
    # - 各コマンドを個別にテスト可能
}

main() unless caller;

1;

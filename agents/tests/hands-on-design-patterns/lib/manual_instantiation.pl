#!/usr/bin/env perl
use v5.36;
use warnings;

# 第4回: コマンド工場を作る〜名前からコマンドを生成
# コード例1: manual_instantiation.pl（破綻版）
# コマンドを手動でインスタンス化

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
    sub execute ($self, $args, $ctx) {"Available commands: /hello, /help, /status, /joke, /weather"}
}

package StatusCommand {
    use Moo;
    with 'Command';
    sub execute ($self, $args, $ctx) {"Bot status: online"}
}

package JokeCommand {
    use Moo;
    with 'Command';
    sub execute ($self, $args, $ctx) {"Why do programmers prefer dark mode? Because light attracts bugs!"}
}

package WeatherCommand {
    use Moo;
    with 'Command';
    sub execute ($self, $args, $ctx) { "Weather in " . ($args || 'Tokyo') . ": 15°C, Sunny" }
}

# ===== Bot本体 =====
package ManualBot {
    use Moo;

    # 問題: 新しいコマンドを追加するたびにここを修正
    sub get_command ($self, $name) {

        # 手動でインスタンスを生成
        if ($name eq 'hello') {
            return HelloCommand->new;
        }
        elsif ($name eq 'help') {
            return HelpCommand->new;
        }
        elsif ($name eq 'status') {
            return StatusCommand->new;
        }
        elsif ($name eq 'joke') {
            return JokeCommand->new;
        }
        elsif ($name eq 'weather') {
            return WeatherCommand->new;
        }

        # 新しいコマンドを追加するたびにelsifを追加...
        # /translate, /remind, /meme, /quote, etc...

        return undef;
    }

    sub handle_message ($self, $message) {
        if ($message =~ m{^/(\w+)\s*(.*)$}) {
            my ($cmd_name, $args) = ($1, $2);
            if (my $command = $self->get_command($cmd_name)) {
                return $command->execute($args, {});
            }
            return "Unknown command: /$cmd_name";
        }
        return undef;
    }
}

sub main {
    my $bot = ManualBot->new;

    my @messages = ("/hello World", "/help", "/status", "/joke", "/weather Osaka",);

    for my $msg (@messages) {
        my $response = $bot->handle_message($msg);
        say "User: $msg";
        say "Bot: " . ($response // "(no response)");
        say "---";
    }

    # 問題点:
    # - get_commandメソッドが肥大化（コマンド追加のたびに修正）
    # - コマンドクラスとget_commandの両方を修正する必要
    # - Open-Closed原則に違反
}

main() unless caller;

1;

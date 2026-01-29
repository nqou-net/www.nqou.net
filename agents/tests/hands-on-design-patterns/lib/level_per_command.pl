#!/usr/bin/env perl
use v5.36;
use warnings;

# 第7回: ユーザーを見分ける〜戦略の自動選択
# コード例1: level_per_command.pl（破綻版）
# 各コマンドでユーザーレベルを判定

package Command {
    use Moo::Role;
    requires 'execute';
}

# 問題: 各コマンドでレベル判定を重複して行う
package HelpCommand {
    use Moo;
    with 'Command';

    sub execute ($self, $args, $ctx) {
        my $user  = $ctx->{user};
        my $level = $user->{level} // 'beginner';

        # レベル判定が各コマンドで重複
        if ($level eq 'expert') {
            return "Commands: /hello, /help, /status, /config, /debug, /admin";
        }
        elsif ($level eq 'intermediate') {
            return "Commands: /hello, /help, /status, /config";
        }
        else {    # beginner
            return "Commands: /hello, /help, /status\n(Tip: Type /hello to greet the bot!)";
        }
    }
}

package StatusCommand {
    use Moo;
    with 'Command';

    sub execute ($self, $args, $ctx) {
        my $user  = $ctx->{user};
        my $level = $user->{level} // 'beginner';

        # また同じレベル判定...
        if ($level eq 'expert') {
            return "Status: OK | Uptime: 42d 3h | Memory: 128MB | Load: 0.5";
        }
        elsif ($level eq 'intermediate') {
            return "Status: OK | Uptime: 42 days";
        }
        else {    # beginner
            return "The bot is working fine! 😊";
        }
    }
}

package ErrorCommand {
    use Moo;
    with 'Command';

    sub execute ($self, $args, $ctx) {
        my $user  = $ctx->{user};
        my $level = $user->{level} // 'beginner';

        # さらに同じレベル判定...
        if ($level eq 'expert') {
            return "Error 0x0042: Connection timeout at line 128. Stack trace available.";
        }
        elsif ($level eq 'intermediate') {
            return "Error: Connection timeout. Please check your network.";
        }
        else {    # beginner
            return "Oops! Something went wrong. Please try again later.";
        }
    }
}

package LevelBot {
    use Moo;
    has 'commands' => (is => 'ro', default => sub { {} });
    has 'users'    => (is => 'ro', default => sub { {} });

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
                return $command->execute($args, {user => $user});
            }
            return "Unknown command: /$cmd_name";
        }
        return undef;
    }
}

sub main {
    my $bot = LevelBot->new;

    for my $user (qw(alice bob carol)) {
        say "=== User: $user ===";
        for my $cmd (qw(/help /status /error)) {
            my $response = $bot->handle_message($user, $cmd);
            say "$cmd: $response";
        }
        say "";
    }

    say "問題点:";
    say "- 各コマンドでレベル判定を重複実装";
    say "- 新しいレベル追加には全コマンドを修正";
    say "- レベル判定ロジックが散在";
}

main() unless caller;

1;

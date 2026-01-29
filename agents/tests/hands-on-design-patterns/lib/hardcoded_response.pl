#!/usr/bin/env perl
use v5.36;
use warnings;

# 第6回: Botの性格を変える〜フレンドリー/フォーマル
# コード例1: hardcoded_response.pl（破綻版）
# 応答文がハードコードされている

package Command {
    use Moo::Role;
    requires 'execute';
}

package HelloCommand {
    use Moo;
    with 'Command';

    sub execute ($self, $args, $ctx) {
        my $name = $args || 'Guest';

        # 問題: 応答スタイルがハードコード
        return "Hello, $name!";
    }
}

package HelpCommand {
    use Moo;
    with 'Command';

    sub execute ($self, $args, $ctx) {

        # 問題: フォーマルな言い方にしたい場合は全コマンドを修正
        return "Available commands: /hello, /help, /status";
    }
}

package StatusCommand {
    use Moo;
    with 'Command';

    sub execute ($self, $args, $ctx) {

        # 問題: 絵文字を追加したい場合も全コマンドを修正
        return "Bot is running normally.";
    }
}

package ErrorCommand {
    use Moo;
    with 'Command';

    sub execute ($self, $args, $ctx) {

        # 問題: エラーメッセージのトーンも統一したい
        return "Sorry, something went wrong.";
    }
}

package HardcodedBot {
    use Moo;
    has 'commands' => (is => 'ro', default => sub { {} });

    sub BUILD ($self, $args) {
        $self->commands->{hello}  = HelloCommand->new;
        $self->commands->{help}   = HelpCommand->new;
        $self->commands->{status} = StatusCommand->new;
        $self->commands->{error}  = ErrorCommand->new;
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
    my $bot = HardcodedBot->new;

    my @messages = ("/hello World", "/help", "/status", "/error",);

    for my $msg (@messages) {
        my $response = $bot->handle_message($msg);
        say "User: $msg";
        say "Bot: " . ($response // "(no response)");
        say "---";
    }

    say "";
    say "問題点:";
    say "- 応答スタイルがハードコード";
    say "- フレンドリー/フォーマルを切り替えられない";
    say "- スタイル変更には全コマンドの修正が必要";
    say "- 新しいスタイル（絵文字多め、敬語等）追加が困難";
}

main() unless caller;

1;

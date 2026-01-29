#!/usr/bin/env perl
use v5.36;
use warnings;

# 第8回: 執事の業務日報〜コマンド実行ログ
# コード例1: simple_log.pl（破綻版）
# ログ出力のみで、他の通知機能が追加しにくい

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
    sub execute ($self, $args, $ctx) {"Available commands: /hello, /help, /status"}
}

package StatusCommand {
    use Moo;
    with 'Command';
    sub execute ($self, $args, $ctx) {"Bot status: online"}
}

# ===== 問題のあるBot =====
package SimpleLogBot {
    use Moo;
    use Time::Piece;

    has 'commands' => (is => 'ro', default => sub { {} });
    has 'log_file' => (is => 'ro', default => 'bot.log');

    sub BUILD ($self, $args) {
        $self->commands->{hello}  = HelloCommand->new;
        $self->commands->{help}   = HelpCommand->new;
        $self->commands->{status} = StatusCommand->new;
    }

    sub handle_message ($self, $user_id, $message) {
        if ($message =~ m{^/(\w+)\s*(.*)$}) {
            my ($cmd_name, $args) = ($1, $2);
            if (my $command = $self->commands->{$cmd_name}) {
                my $result = $command->execute($args, {});

                # 問題: ログ出力がハードコード
                $self->_log_command($user_id, $cmd_name, $args);

                # メール通知も欲しい場合は？
                # $self->_send_email(...);  # ここに追加？

                # Slack通知も欲しい場合は？
                # $self->_notify_slack(...);  # さらに追加？

                # メトリクス収集も？
                # $self->_record_metrics(...);  # どんどん肥大化...

                return $result;
            }
            return "Unknown command: /$cmd_name";
        }
        return undef;
    }

    sub _log_command ($self, $user_id, $cmd_name, $args) {
        my $timestamp = localtime->strftime('%Y-%m-%d %H:%M:%S');
        my $log_line  = "[$timestamp] User: $user_id, Command: /$cmd_name, Args: $args\n";

        # ファイルに出力（実際にはSTDOUTに）
        print "LOG: $log_line";
    }
}

sub main {
    my $bot = SimpleLogBot->new;

    for my $user (qw(alice bob)) {
        for my $msg ("/hello World", "/help", "/status") {
            say "---";
            say "User [$user]: $msg";
            my $response = $bot->handle_message($user, $msg);
            say "Bot: $response";
        }
    }

    say "";
    say "問題点:";
    say "- ログ出力がhandle_messageにハードコード";
    say "- 通知先を追加するたびにhandle_messageを修正";
    say "- 通知ロジックがBotと密結合";
    say "- テストが困難（実際にログファイルを作成してしまう）";
}

main() unless caller;

1;

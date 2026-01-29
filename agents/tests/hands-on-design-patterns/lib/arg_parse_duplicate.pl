#!/usr/bin/env perl
use v5.36;
use warnings;

# 第3回: コマンドに引数を渡す〜/weather Tokyo
# コード例1: arg_parse_duplicate.pl（破綻版）
# 各コマンドで引数解析が重複

package Command {
    use Moo::Role;
    requires 'execute';
}

# 引数解析が各コマンドで重複している
package WeatherCommand {
    use Moo;
    with 'Command';

    # 天気データ（モック）
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

    sub execute ($self, $args, $context) {

        # 引数解析: 各コマンドで同じようなコードを書く必要がある
        my @parts = split /\s+/, ($args // '');
        my $city  = $parts[0] // '';

        if (!$city) {
            return "Usage: /weather <city>";
        }

        my $data = $self->weather_data->{lc $city};
        if (!$data) {
            return "Unknown city: $city";
        }

        return "$city: $data->{temp}°C, $data->{condition}";
    }
}

package RemindCommand {
    use Moo;
    with 'Command';

    sub execute ($self, $args, $context) {

        # 引数解析: またも同じようなパースコード...
        my @parts   = split /\s+/, ($args // ''), 2;
        my $time    = $parts[0] // '';
        my $message = $parts[1] // '';

        if (!$time || !$message) {
            return "Usage: /remind <time> <message>";
        }

        return "Reminder set: '$message' at $time";
    }
}

package TranslateCommand {
    use Moo;
    with 'Command';

    sub execute ($self, $args, $context) {

        # 引数解析: さらに同じようなパースコード...
        # --from=en --to=ja のようなオプションも欲しくなる
        my @parts = split /\s+/, ($args // ''), 3;
        my $from  = $parts[0] // '';
        my $to    = $parts[1] // '';
        my $text  = $parts[2] // '';

        if (!$from || !$to || !$text) {
            return "Usage: /translate <from> <to> <text>";
        }

        # 翻訳はモック
        return "Translated ($from -> $to): [$text]";
    }
}

package CommandBot {
    use Moo;
    has 'commands' => (is => 'ro', default => sub { {} });

    sub register ($self, $name, $command) {
        $self->commands->{$name} = $command;
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
    $bot->register('weather', WeatherCommand->new)->register('remind', RemindCommand->new)->register('translate', TranslateCommand->new);

    my @messages = (
        "/weather Tokyo",
        "/weather",    # エラー
        "/remind 10:00 Meeting",
        "/remind",     # エラー
        "/translate en ja Hello",
    );

    for my $msg (@messages) {
        my $response = $bot->handle_message($msg);
        say "User: $msg";
        say "Bot: " . ($response // "(no response)");
        say "---";
    }

    # 問題点:
    # - 引数解析コードが各コマンドで重複
    # - オプション（--from=en）のパースを追加すると全コマンドで修正が必要
    # - 引数のバリデーションロジックも重複
}

main() unless caller;

1;

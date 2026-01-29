#!/usr/bin/env perl
use v5.36;
use warnings;

# 第4回: コマンド工場を作る〜名前からコマンドを生成
# コード例2: factory_auto.pl（改善版）
# Factoryパターンでコマンドを自動登録・生成

# ===== コマンドFactory =====
package CommandFactory {
    use Moo;

    has 'registry' => (is => 'ro', default => sub { {} });

    # コマンドクラスを登録
    sub register ($self, $name, $class) {
        $self->registry->{$name} = $class;
        return $self;
    }

    # 名前からコマンドインスタンスを生成
    sub create ($self, $name) {
        my $class = $self->registry->{$name};
        return undef unless $class;
        return $class->new;
    }

    # 登録されているコマンド一覧
    sub list ($self) {
        return sort keys %{$self->registry};
    }
}

# ===== コマンド基底Role =====
package Command {
    use Moo::Role;
    requires 'execute';
}

# ===== 各コマンド実装 =====
package HelloCommand {
    use Moo;
    with 'Command';
    sub execute ($self, $args, $ctx) { "Hello, " . ($args || 'Guest') . "!" }
}

package HelpCommand {
    use Moo;
    with 'Command';

    sub execute ($self, $args, $ctx) {
        my @commands = $ctx->{factory}->list;
        return "Available commands: " . join(", ", map {"/$_"} @commands);
    }
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
package FactoryBot {
    use Moo;

    has 'factory' => (is => 'ro', required => 1);

    sub handle_message ($self, $message) {
        if ($message =~ m{^/(\w+)\s*(.*)$}) {
            my ($cmd_name, $args) = ($1, $2);
            if (my $command = $self->factory->create($cmd_name)) {
                my $context = {factory => $self->factory};
                return $command->execute($args, $context);
            }
            return "Unknown command: /$cmd_name";
        }
        return undef;
    }
}

sub main {

    # Factoryにコマンドを登録
    my $factory = CommandFactory->new;
    $factory->register('hello', 'HelloCommand')
        ->register('help',    'HelpCommand')
        ->register('status',  'StatusCommand')
        ->register('joke',    'JokeCommand')
        ->register('weather', 'WeatherCommand');

    my $bot = FactoryBot->new(factory => $factory);

    my @messages = ("/hello World", "/help", "/status", "/joke", "/weather Osaka",);

    for my $msg (@messages) {
        my $response = $bot->handle_message($msg);
        say "User: $msg";
        say "Bot: " . ($response // "(no response)");
        say "---";
    }

    # 改善点:
    # - Factoryに登録するだけで新しいコマンドが使える
    # - Bot本体のコードは一切変更不要
    # - コマンド一覧も自動取得
    # - 設定ファイルからの動的登録も容易
}

main() unless caller;

1;

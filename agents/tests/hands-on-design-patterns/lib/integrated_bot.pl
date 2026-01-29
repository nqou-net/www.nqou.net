#!/usr/bin/env perl
use v5.36;
use warnings;

# 第9回: 執事Botを完成させる〜コマンド帝国の支配者に
# コード例1: integrated_bot.pl（統合版・バグあり）
# 全パターンを統合するが、インターフェース不整合でバグが発生

package Command {
    use Moo::Role;
    requires 'execute';
}

# コマンド実装
package HelloCommand {
    use Moo;
    with 'Command';

    sub execute ($self, $args, $ctx) {
        my $name = $args || 'Guest';

        # バグ: strategyを使うべきだが直接返している
        return "Hello, $name!";
    }
}

package HelpCommand {
    use Moo;
    with 'Command';

    sub execute ($self, $args, $ctx) {

        # バグ: factoryからコマンド一覧を取得すべきだが固定
        return "Commands: /hello, /help, /status";
    }
}

package StatusCommand {
    use Moo;
    with 'Command';

    sub execute ($self, $args, $ctx) {

        # バグ: strategyを使うべきだが直接返している
        return "Bot is running.";
    }
}

# Factory
package CommandFactory {
    use Moo;
    has 'registry' => (is => 'ro', default => sub { {} });

    sub register ($self, $name, $class) {
        $self->registry->{$name} = $class;
        return $self;
    }

    sub create ($self, $name) {
        my $class = $self->registry->{$name};
        return undef unless $class;
        return $class->new;
    }

    sub list ($self) { sort keys %{$self->registry} }
}

# Strategy（簡略版）
package ResponseStrategy {
    use Moo::Role;
    requires 'format';
}

package FriendlyStrategy {
    use Moo;
    with 'ResponseStrategy';
    sub format ($self, $msg) {"😊 $msg"}
}

# Observer（簡略版）
package Observer {
    use Moo::Role;
    requires 'update';
}

package LogObserver {
    use Moo;
    with 'Observer';

    sub update ($self, $event) {
        say "[LOG] $event->{command} by $event->{user}";
    }
}

# Bot
package IntegratedBot {
    use Moo;

    has 'factory'   => (is => 'ro', required => 1);
    has 'strategy'  => (is => 'rw');
    has 'observers' => (is => 'ro', default => sub { [] });

    sub attach ($self, $observer) {
        push @{$self->observers}, $observer;
        return $self;
    }

    sub notify ($self, $event) {
        $_->update($event) for @{$self->observers};
    }

    sub handle_message ($self, $user_id, $message) {
        if ($message =~ m{^/(\w+)\s*(.*)$}) {
            my ($cmd_name, $args) = ($1, $2);
            if (my $command = $self->factory->create($cmd_name)) {

                # バグ: contextにfactory, strategyを渡し忘れ
                my $result = $command->execute($args, {});

                # 出力をstrategyでフォーマットすべきだが忘れている

                $self->notify({command => $cmd_name, user => $user_id});
                return $result;
            }
            return "Unknown: /$cmd_name";
        }
        return undef;
    }
}

sub main {
    my $factory = CommandFactory->new;
    $factory->register('hello', 'HelloCommand')->register('help', 'HelpCommand')->register('status', 'StatusCommand');

    my $bot = IntegratedBot->new(factory => $factory);
    $bot->strategy(FriendlyStrategy->new);
    $bot->attach(LogObserver->new);

    say "=== Integrated Bot (with bugs) ===";
    for my $msg ("/hello World", "/help", "/status") {
        say "";
        say "User: $msg";
        my $response = $bot->handle_message('alice', $msg);
        say "Bot: $response";
    }

    say "";
    say "問題点:";
    say "- strategyを設定したのに使われていない";
    say "- helpコマンドがfactoryから一覧を取得していない";
    say "- 各コンポーネント間のインターフェースが不統一";
}

main() unless caller;

1;

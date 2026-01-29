#!/usr/bin/env perl
use v5.36;
use warnings;

# 第5回: プラグインシステム〜コマンドを外部ファイルで追加
# コード例2: plugin_meta.pl（改善版）
# プラグインにメタデータを持たせる

# ===== プラグインメタデータRole =====
package Plugin {
    use Moo::Role;

    # プラグインメタデータ（サブクラスでオーバーライド）
    sub meta_info ($self) {
        return {
            name        => 'unknown',
            version     => '0.0.1',
            description => 'No description',
            command     => 'unknown',
            author      => 'Anonymous',
            requires    => [],                 # 依存するプラグイン
        };
    }
}

# ===== コマンド基底Role =====
package Command {
    use Moo::Role;
    with 'Plugin';
    requires 'execute';
}

# ===== サンプルプラグイン =====
package GreetCommand {
    use Moo;
    with 'Command';

    sub meta_info ($self) {
        return {
            name        => 'GreetCommand',
            version     => '1.0.0',
            description => 'Greet users with customizable messages',
            command     => 'greet',
            author      => 'Butler Bot Team',
            requires    => [],
        };
    }

    sub execute ($self, $args, $ctx) {
        my $name = $args || 'Guest';
        return "Greetings, $name! Welcome to our service.";
    }
}

package QuoteCommand {
    use Moo;
    with 'Command';

    has 'quotes' => (
        is      => 'ro',
        default => sub {
            [
                "The only way to do great work is to love what you do. - Steve Jobs",
                "Code is like humor. When you have to explain it, it's bad. - Cory House",
                "First, solve the problem. Then, write the code. - John Johnson",
            ]
        }
    );

    sub meta_info ($self) {
        return {
            name        => 'QuoteCommand',
            version     => '1.2.0',
            description => 'Display inspirational programming quotes',
            command     => 'quote',
            author      => 'Butler Bot Team',
            requires    => [],
        };
    }

    sub execute ($self, $args, $ctx) {
        my $quotes = $self->quotes;
        return $quotes->[rand @$quotes];
    }
}

package MemeCommand {
    use Moo;
    with 'Command';

    sub meta_info ($self) {
        return {
            name        => 'MemeCommand',
            version     => '0.5.0',
            description => 'Generate programming memes',
            command     => 'meme',
            author      => 'Butler Bot Team',
            requires    => ['quote'],                      # QuoteCommandに依存
        };
    }

    sub execute ($self, $args, $ctx) {
        return "[Meme] When the code works on the first try... (suspicious look)";
    }
}

# ===== プラグインマネージャー =====
package PluginManager {
    use Moo;

    has 'plugins'    => (is => 'ro', default => sub { {} });
    has 'load_order' => (is => 'ro', default => sub { [] });

    # プラグインを登録（依存関係を考慮）
    sub register ($self, $plugin) {
        my $meta = $plugin->meta_info;
        my $name = $meta->{name};

        # 依存関係チェック
        for my $dep (@{$meta->{requires}}) {
            unless (exists $self->plugins->{$dep} || $self->_find_by_command($dep)) {
                warn "Warning: Plugin '$name' requires '$dep' which is not loaded\n";
            }
        }

        $self->plugins->{$meta->{command}} = {
            instance => $plugin,
            meta     => $meta,
        };
        push @{$self->load_order}, $meta->{command};

        return $self;
    }

    sub _find_by_command ($self, $cmd) {
        return exists $self->plugins->{$cmd};
    }

    # コマンドを取得
    sub get_command ($self, $name) {
        my $entry = $self->plugins->{$name};
        return $entry ? $entry->{instance} : undef;
    }

    # 全プラグイン情報
    sub list_plugins ($self) {
        return map {
            my $entry = $self->plugins->{$_};
            {
                command     => $_,
                name        => $entry->{meta}{name},
                version     => $entry->{meta}{version},
                description => $entry->{meta}{description},
            }
        } @{$self->load_order};
    }
}

# ===== Bot本体 =====
package PluginBot {
    use Moo;

    has 'plugin_manager' => (is => 'ro', required => 1);

    sub handle_message ($self, $message) {
        if ($message =~ m{^/(\w+)\s*(.*)$}) {
            my ($cmd_name, $args) = ($1, $2);

            if ($cmd_name eq 'plugins') {

                # プラグイン一覧表示
                my @plugins = $self->plugin_manager->list_plugins;
                my $list    = join("\n", map {"  /$_->{command} v$_->{version} - $_->{description}"} @plugins);
                return "Installed plugins:\n$list";
            }

            if (my $command = $self->plugin_manager->get_command($cmd_name)) {
                return $command->execute($args, {});
            }
            return "Unknown command: /$cmd_name";
        }
        return undef;
    }
}

sub main {
    my $pm = PluginManager->new;

    # プラグインを登録（順序は依存関係を考慮）
    $pm->register(GreetCommand->new)->register(QuoteCommand->new)->register(MemeCommand->new);    # quote に依存

    my $bot = PluginBot->new(plugin_manager => $pm);

    my @messages = ("/plugins", "/greet World", "/quote", "/meme",);

    for my $msg (@messages) {
        my $response = $bot->handle_message($msg);
        say "User: $msg";
        say "Bot: " . ($response // "(no response)");
        say "---";
    }

    # 改善点:
    # - プラグインがメタデータを持つ
    # - バージョン、説明、依存関係を明示
    # - プラグイン一覧を動的に取得可能
    # - 依存関係の警告を表示
}

main() unless caller;

1;

#!/usr/bin/env perl
use v5.36;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin";

binmode STDOUT, ':utf8';
binmode STDIN,  ':utf8';

# 第6回: 3つのパターンを統合
# Chain of Responsibility + State + Memento の連携

use Storable qw(dclone);

# ========================================
# Memento
# ========================================
package GameMemento {
    use Moo;
    use Storable qw(dclone);

    has state     => (is => 'ro', required => 1);
    has label     => (is => 'ro', default  => 'セーブ');
    has timestamp => (is => 'ro', default  => sub { time() });

    sub BUILDARGS($class, %args) {
        $args{state} = dclone($args{state}) if exists $args{state};
        return \%args;
    }

    sub get_state($self) { dclone($self->state) }

    sub describe($self) {
        sprintf('%s (場所: %s, HP: %s)', $self->label, $self->state->{location} // '?', $self->state->{hp} // '?');
    }
}

package SaveManager {
    use Moo;

    has saves     => (is => 'rw', default => sub { [] });
    has max_saves => (is => 'ro', default => 10);

    sub save($self, $context, $label = 'セーブ') {
        my $memento = GameMemento->new(state => $context, label => $label);
        my @saves   = @{$self->saves};
        push @saves, $memento;
        shift @saves if @saves > $self->max_saves;
        $self->saves(\@saves);
        return 'セーブ完了: ' . $memento->describe;
    }

    sub load_latest($self) {
        my @saves = @{$self->saves};
        return (undef, 'セーブデータなし') unless @saves;
        my $m = $saves[-1];
        return ($m->get_state, 'ロード: ' . $m->describe);
    }

    sub list_saves($self) {
        my @saves = @{$self->saves};
        return 'セーブデータなし' unless @saves;
        my @lines = ('セーブ一覧:');
        push @lines, sprintf('  [%d] %s', $_, $saves[$_]->describe) for 0 .. $#saves;
        join("\n", @lines);
    }
}

# ========================================
# Chain of Responsibility
# ========================================
package CommandHandler {
    use Moo::Role;

    has next_handler => (is => 'rw', predicate => 'has_next');

    requires 'can_handle';
    requires 'handle';

    sub set_next($self, $h) { $self->next_handler($h); $h }

    sub process($self, $game, $cmd) {
        return $self->handle($game, $cmd)                if $self->can_handle($game, $cmd);
        return $self->next_handler->process($game, $cmd) if $self->has_next;
        return {handled => 0, message => 'コマンド不明。「ヘルプ」で確認。'};
    }
}

package MoveHandler {
    use Moo;
    with 'CommandHandler';

    my %MAP = (
        '森の入り口' => {'北' => '小道'},
        '小道'    => {'北' => '泉', '東' => '古い小屋', '南' => '森の入り口'},
        '古い小屋'  => {'西' => '小道'},
        '泉'     => {'南' => '小道', '北' => '宝物庫'},
        '宝物庫'   => {'南' => '泉'},
    );

    sub can_handle($self, $game, $cmd) { $cmd =~ /^[北南東西]$/ }

    sub handle($self, $game, $cmd) {
        my $ctx  = $game->context;
        my $next = $MAP{$ctx->{location}}{$cmd};

        if ($next) {

            # 宝物庫は鍵が必要
            if ($next eq '宝物庫' && !$ctx->{unlocked}{'宝物庫'}) {
                return {handled => 1, message => '扉は鍵がかかっている。'};
            }

            $ctx->{location} = $next;

            # 泉に入るとゴブリン戦闘
            if ($next eq '泉' && !$ctx->{defeated}{'ゴブリン'}) {
                $game->change_state(BattleState->new(enemy_name => 'ゴブリン', enemy_hp => 40));
                return {handled => 1, message => "${cmd}に進んだ。"};
            }

            return {handled => 1, message => "${cmd}に進んだ。"};
        }
        return {handled => 1, message => 'そちらには進めない。'};
    }
}

package ExamineHandler {
    use Moo;
    with 'CommandHandler';

    my %ITEMS = (
        '古い小屋' => '古びた鍵',
        '泉'    => '回復薬',
    );

    sub can_handle($self, $game, $cmd) { $cmd eq '調べる' }

    sub handle($self, $game, $cmd) {
        my $ctx  = $game->context;
        my $item = $ITEMS{$ctx->{location}};

        if ($item && !grep { $_ eq $item } @{$ctx->{inventory}}) {
            push @{$ctx->{inventory}}, $item;
            return {handled => 1, message => "${item}を見つけた！"};
        }
        return {handled => 1, message => '特に何もない。'};
    }
}

package UseItemHandler {
    use Moo;
    with 'CommandHandler';

    sub can_handle($self, $game, $cmd) { $cmd =~ /^使う\s+/ }

    sub handle($self, $game, $cmd) {
        my ($item) = $cmd =~ /^使う\s+(.+)$/;
        my $ctx    = $game->context;
        my $inv    = $ctx->{inventory};

        my $idx = -1;
        $inv->[$_] eq $item and $idx = $_ and last for 0 .. $#$inv;

        return {handled => 1, message => 'そのアイテムはない。'} if $idx < 0;

        if ($item eq '古びた鍵' && $ctx->{location} eq '泉') {
            splice(@$inv, $idx, 1);
            $ctx->{unlocked}{'宝物庫'} = 1;
            return {handled => 1, message => '鍵を使った。宝物庫への道が開いた！'};
        }
        elsif ($item eq '回復薬') {
            splice(@$inv, $idx, 1);
            $ctx->{hp} = ($ctx->{hp} + 30 > 100) ? 100 : $ctx->{hp} + 30;
            return {handled => 1, message => '回復薬を使った。HP: ' . $ctx->{hp}};
        }
        return {handled => 1, message => 'ここでは使えない。'};
    }
}

package InventoryHandler {
    use Moo;
    with 'CommandHandler';

    sub can_handle($self, $game, $cmd) { $cmd eq '持ち物' }

    sub handle($self, $game, $cmd) {
        my @items = @{$game->context->{inventory}};
        return {handled => 1, message => @items ? '持ち物: ' . join(', ', @items) : '何もない。'};
    }
}

package SaveHandler {
    use Moo;
    with 'CommandHandler';

    sub can_handle($self, $game, $cmd) { $cmd eq 'セーブ' }

    sub handle($self, $game, $cmd) {
        my $msg = $game->save_manager->save($game->context);
        return {handled => 1, message => $msg};
    }
}

package LoadHandler {
    use Moo;
    with 'CommandHandler';

    sub can_handle($self, $game, $cmd) { $cmd eq 'ロード' }

    sub handle($self, $game, $cmd) {
        my ($state, $msg) = $game->save_manager->load_latest;
        if ($state) {
            $game->restore_context($state);
            $game->change_state(ExplorationState->new);
        }
        return {handled => 1, message => $msg};
    }
}

package SaveListHandler {
    use Moo;
    with 'CommandHandler';

    sub can_handle($self, $game, $cmd) { $cmd eq 'セーブ一覧' }

    sub handle($self, $game, $cmd) {
        return {handled => 1, message => $game->save_manager->list_saves};
    }
}

package HelpHandler {
    use Moo;
    with 'CommandHandler';

    sub can_handle($self, $game, $cmd) { $cmd eq 'ヘルプ' }

    sub handle($self, $game, $cmd) {
        return {
            handled => 1,
            message => 'コマンド: 北,南,東,西,調べる,使う [アイテム],持ち物,セーブ,ロード,セーブ一覧,終了'
        };
    }
}

package QuitHandler {
    use Moo;
    with 'CommandHandler';

    sub can_handle($self, $game, $cmd) { $cmd eq '終了' }

    sub handle($self, $game, $cmd) {
        $game->context->{running} = 0;
        return {handled => 1, message => 'ゲーム終了。'};
    }
}

# ========================================
# State
# ========================================
package GameStateRole {
    use Moo::Role;
    requires 'name';
    requires 'process_command';
    requires 'on_enter';
}

package ExplorationState {
    use Moo;
    with 'GameStateRole';

    sub name($self)            {'探索'}
    sub on_enter($self, $game) {''}

    sub process_command($self, $game, $cmd) {

        # ハンドラチェーンに委譲
        return $game->handler_chain->process($game, $cmd);
    }
}

package BattleState {
    use Moo;
    with 'GameStateRole';

    has enemy_name => (is => 'ro', required => 1);
    has enemy_hp   => (is => 'rw', required => 1);

    sub name($self) {'戦闘'}

    sub on_enter($self, $game) {
        return $self->enemy_name . 'が現れた！';
    }

    sub process_command($self, $game, $cmd) {
        my $ctx = $game->context;

        if ($cmd eq '攻撃') {
            my $dmg = int(rand(20)) + 10;
            $self->enemy_hp($self->enemy_hp - $dmg);

            if ($self->enemy_hp <= 0) {
                $ctx->{defeated}{$self->enemy_name} = 1;
                $game->change_state(ExplorationState->new);
                return {handled => 1, message => $self->enemy_name . "に${dmg}ダメージ！倒した！"};
            }

            my $counter = int(rand(10)) + 5;
            $ctx->{hp} -= $counter;
            return {
                handled => 1,
                message => $self->enemy_name . "に${dmg}ダメージ！反撃で${counter}ダメージ。HP: $ctx->{hp}"
            };
        }
        elsif ($cmd eq '逃げる') {
            $ctx->{location} = '小道';
            $game->change_state(ExplorationState->new);
            return {handled => 1, message => '逃げた！小道に戻った。'};
        }
        elsif ($cmd =~ /^使う\s+回復薬$/) {
            my $inv = $ctx->{inventory};
            for my $i (0 .. $#$inv) {
                if ($inv->[$i] eq '回復薬') {
                    splice(@$inv, $i, 1);
                    $ctx->{hp} = ($ctx->{hp} + 30 > 100) ? 100 : $ctx->{hp} + 30;
                    return {handled => 1, message => "回復薬使用。HP: $ctx->{hp}"};
                }
            }
            return {handled => 1, message => '回復薬がない。'};
        }
        elsif ($cmd eq 'ヘルプ') {
            return {handled => 1, message => '戦闘中: 攻撃, 逃げる, 使う 回復薬'};
        }

        return {handled => 1, message => '戦闘中はそれは使えない！'};
    }
}

# ========================================
# Game (統合)
# ========================================
package AdventureGame {
    use Moo;

    has context => (
        is      => 'rw',
        default => sub {
            {
                location  => '森の入り口',
                hp        => 100,
                inventory => [],
                unlocked  => {},
                defeated  => {},
                running   => 1,
            }
        },
    );

    has state         => (is => 'rw', default => sub { ExplorationState->new });
    has save_manager  => (is => 'ro', default => sub { SaveManager->new });
    has handler_chain => (is => 'lazy');

    sub _build_handler_chain($self) {
        my $move = MoveHandler->new;
        $move->set_next(ExamineHandler->new)
            ->set_next(UseItemHandler->new)
            ->set_next(InventoryHandler->new)
            ->set_next(SaveHandler->new)
            ->set_next(LoadHandler->new)
            ->set_next(SaveListHandler->new)
            ->set_next(HelpHandler->new)
            ->set_next(QuitHandler->new);
        return $move;
    }

    sub change_state($self, $new_state) {
        $self->state($new_state);
        my $msg = $new_state->on_enter($self);
        say $msg if $msg;
    }

    sub restore_context($self, $state) {
        $self->context($state);
    }

    sub describe_location($self) {
        my %desc = (
            '森の入り口' => '薄暗い森の入り口。北に小道。',
            '小道'    => '木々に囲まれた小道。東に小屋、北に泉。',
            '古い小屋'  => '朽ちかけた小屋。何かありそう。',
            '泉'     => '澄んだ泉。北に扉がある。',
            '宝物庫'   => '金銀財宝！冒険クリア！',
        );
        return $desc{$self->context->{location}} // '見知らぬ場所。';
    }

    sub run($self) {
        say '=== タイムトラベル冒険ゲーム ===';
        say '（Chain of Responsibility + State + Memento）';
        say '';

        while ($self->context->{running}) {
            my $ctx = $self->context;
            say "HP: $ctx->{hp}/100 | モード: " . $self->state->name;
            say '現在地: ' . $ctx->{location};
            say $self->describe_location();
            print '> ';
            my $input = <STDIN>;
            chomp($input);

            my $result = $self->state->process_command($self, $input);
            say $result->{message};
            say '';

            if ($ctx->{hp} <= 0) {
                say 'ゲームオーバー...ロードしますか？(y/n)';
                my $ans = <STDIN>;
                chomp($ans);
                if ($ans eq 'y') {
                    my ($state, $msg) = $self->save_manager->load_latest;
                    if ($state) {
                        $self->restore_context($state);
                        $self->change_state(ExplorationState->new);
                        say $msg;
                    }
                    else {
                        say $msg;
                        $ctx->{running} = 0;
                    }
                }
                else {
                    $ctx->{running} = 0;
                }
            }

            if ($ctx->{location} eq '宝物庫') {
                say 'おめでとう！冒険クリア！';
                $ctx->{running} = 0;
            }
        }
    }
}

unless (caller) {
    my $game = AdventureGame->new;
    $game->run;
}

1;

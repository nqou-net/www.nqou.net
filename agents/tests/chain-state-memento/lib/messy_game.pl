#!/usr/bin/env perl
use v5.36;
use warnings;

# 第2回: コマンドが増えると大変！（if/else肥大化版）
# 攻撃・使う・話すなど追加し、条件分岐が爆発した状態

package Item {
    use Moo;
    has name   => (is => 'ro', required => 1);
    has effect => (is => 'ro', default  => sub { {} });
}

package Enemy {
    use Moo;
    has name => (is => 'ro', required => 1);
    has hp   => (is => 'rw', required => 1);
}

package MessyGame {
    use Moo;

    has location  => (is => 'rw', default => '森の入り口');
    has running   => (is => 'rw', default => 1);
    has hp        => (is => 'rw', default => 100);
    has max_hp    => (is => 'ro', default => 100);
    has inventory => (is => 'rw', default => sub { [] });
    has enemy     => (is => 'rw');
    has in_battle => (is => 'rw', default => 0);
    has npcs      => (is => 'ro', default => sub { {'古い小屋' => '老人'} });
    has talked    => (is => 'rw', default => sub { {} });

    sub describe_location($self) {
        my %descriptions = (
            '森の入り口' => '薄暗い森の入り口に立っている。北に小道が続いている。',
            '小道'    => '木々に囲まれた小道。東に古い小屋、北には泉がある。',
            '古い小屋'  => '朽ちかけた小屋。老人がいる。',
            '泉'     => '澄んだ水の泉。ゴブリンがうろついている！',
            '宝物庫'   => '金銀財宝が眠る部屋。冒険のゴールだ！',
        );
        return $descriptions{$self->location} // '見知らぬ場所にいる。';
    }

    sub process_command($self, $input) {

        # NOTE: 明らかに肥大化したif/else構造
        # 新しいコマンドを追加するたびにここが膨れ上がる

        # 戦闘中かどうかで分岐
        if ($self->in_battle) {

            # 戦闘中のコマンド
            if ($input eq '攻撃') {
                if ($self->enemy) {
                    my $damage = int(rand(20)) + 10;
                    $self->enemy->hp($self->enemy->hp - $damage);
                    if ($self->enemy->hp <= 0) {
                        my $result = $self->enemy->name . 'に' . $damage . 'のダメージ！' . $self->enemy->name . 'を倒した！';
                        $self->in_battle(0);
                        $self->enemy(undef);
                        return $result;
                    }

                    # 敵の反撃
                    my $counter = int(rand(10)) + 5;
                    $self->hp($self->hp - $counter);
                    return $self->enemy->name . 'に' . $damage . 'のダメージ！' . '反撃で' . $counter . 'のダメージを受けた。HP: ' . $self->hp;
                }
                else {
                    return '敵がいない。';
                }
            }
            elsif ($input eq '逃げる') {
                $self->in_battle(0);
                $self->enemy(undef);
                $self->location('小道');
                return '逃げ出した！小道に戻った。';
            }
            elsif ($input =~ /^使う\s+(.+)$/) {
                my $item_name = $1;
                my @items     = @{$self->inventory};
                my $found     = 0;
                for my $i (0 .. $#items) {
                    if ($items[$i]->name eq $item_name) {
                        if ($item_name eq '回復薬') {
                            my $heal = 30;
                            $self->hp($self->hp + $heal);
                            $self->hp($self->max_hp) if $self->hp > $self->max_hp;
                            splice(@{$self->inventory}, $i, 1);
                            return '回復薬を使った。HPが' . $heal . '回復した。HP: ' . $self->hp;
                        }
                        $found = 1;
                        last;
                    }
                }
                return $found ? 'それは戦闘では使えない。' : 'そのアイテムは持っていない。';
            }
            else {
                return '戦闘中！「攻撃」「逃げる」「使う アイテム名」が使えます。';
            }
        }
        else {
            # 通常のコマンド（戦闘外）
            if ($input eq '北') {
                if ($self->location eq '森の入り口') {
                    $self->location('小道');
                    return '北へ進んだ。';
                }
                elsif ($self->location eq '小道') {
                    $self->location('泉');

                    # 敵出現の処理もここに混在
                    $self->enemy(Enemy->new(name => 'ゴブリン', hp => 30));
                    $self->in_battle(1);
                    return '泉にたどり着いた。ゴブリンが現れた！戦闘開始！';
                }
                else {
                    return 'そちらには進めない。';
                }
            }
            elsif ($input eq '東') {
                if ($self->location eq '小道') {
                    $self->location('古い小屋');
                    return '古い小屋に入った。';
                }
                else {
                    return 'そちらには進めない。';
                }
            }
            elsif ($input eq '南') {
                if ($self->location eq '小道') {
                    $self->location('森の入り口');
                    return '森の入り口に戻った。';
                }
                elsif ($self->location eq '泉') {
                    $self->location('小道');
                    return '小道に戻った。';
                }
                else {
                    return 'そちらには進めない。';
                }
            }
            elsif ($input eq '西') {
                if ($self->location eq '古い小屋') {
                    $self->location('小道');
                    return '小道に戻った。';
                }
                else {
                    return 'そちらには進めない。';
                }
            }
            elsif ($input eq '調べる') {
                if ($self->location eq '古い小屋') {
                    my $has_key = grep { $_->name eq '古びた鍵' } @{$self->inventory};
                    if (!$has_key) {
                        push @{$self->inventory}, Item->new(name => '古びた鍵');
                        return '古びた鍵を見つけた！インベントリに追加。';
                    }
                    return '他には何もない。';
                }
                elsif ($self->location eq '泉') {
                    my $has_potion = grep { $_->name eq '回復薬' } @{$self->inventory};
                    if (!$has_potion) {
                        push @{$self->inventory}, Item->new(name => '回復薬');
                        return '泉のほとりで回復薬を見つけた！';
                    }
                    return '他には何もない。';
                }
                else {
                    return '特に何も見つからない。';
                }
            }
            elsif ($input eq '休む') {
                if ($self->location eq '泉' && !$self->in_battle) {
                    my $heal = 20;
                    $self->hp($self->hp + $heal);
                    $self->hp($self->max_hp) if $self->hp > $self->max_hp;
                    return '泉の水で体力が回復した。HP: ' . $self->hp;
                }
                else {
                    return 'ここでは休めない。';
                }
            }
            elsif ($input eq '話す') {
                my $npc = $self->npcs->{$self->location};
                if ($npc) {
                    if (!$self->talked->{$self->location}) {
                        $self->talked->{$self->location} = 1;
                        if ($npc eq '老人') {
                            return '老人「北の泉を越えた先に宝物庫がある。鍵を持っていれば入れるじゃろう。」';
                        }
                    }
                    else {
                        return $npc . 'はもう話すことがないようだ。';
                    }
                }
                return 'ここには話せる相手がいない。';
            }
            elsif ($input =~ /^使う\s+(.+)$/) {
                my $item_name = $1;
                my @items     = @{$self->inventory};
                for my $i (0 .. $#items) {
                    if ($items[$i]->name eq $item_name) {
                        if ($item_name eq '古びた鍵') {
                            if ($self->location eq '泉') {
                                $self->location('宝物庫');
                                splice(@{$self->inventory}, $i, 1);
                                return '古びた鍵を使って宝物庫への扉を開けた！';
                            }
                            else {
                                return 'ここでは使えない。';
                            }
                        }
                        elsif ($item_name eq '回復薬') {
                            my $heal = 30;
                            $self->hp($self->hp + $heal);
                            $self->hp($self->max_hp) if $self->hp > $self->max_hp;
                            splice(@{$self->inventory}, $i, 1);
                            return '回復薬を使った。HPが' . $heal . '回復した。HP: ' . $self->hp;
                        }
                        else {
                            return 'それは使えない。';
                        }
                    }
                }
                return 'そのアイテムは持っていない。';
            }
            elsif ($input eq '持ち物') {
                my @names = map { $_->name } @{$self->inventory};
                return @names ? '持ち物: ' . join(', ', @names) : '何も持っていない。';
            }
            elsif ($input eq 'ヘルプ') {
                return 'コマンド: 北, 南, 東, 西, 調べる, 休む, 話す, 使う [アイテム], 持ち物, 終了';
            }
            elsif ($input eq '終了') {
                $self->running(0);
                return 'ゲームを終了します。';
            }
            else {
                return 'そのコマンドは分からない。「ヘルプ」で確認しよう。';
            }
        }
    }

    sub run($self) {
        say '=== タイムトラベル冒険ゲーム（肥大化版） ===';
        say '';

        while ($self->running) {
            say 'HP: ' . $self->hp . '/' . $self->max_hp;
            say '現在地: ' . $self->location;
            say $self->describe_location();
            say '[戦闘中]' if $self->in_battle;
            print '> ';
            my $input = <STDIN>;
            chomp($input);
            my $result = $self->process_command($input);
            say $result;
            say '';

            if ($self->hp <= 0) {
                say 'ゲームオーバー...';
                $self->running(0);
            }
            if ($self->location eq '宝物庫') {
                say 'おめでとう！冒険クリア！';
                $self->running(0);
            }
        }
    }
}

unless (caller) {
    my $game = MessyGame->new;
    $game->run;
}

1;

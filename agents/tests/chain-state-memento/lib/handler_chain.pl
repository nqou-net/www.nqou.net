#!/usr/bin/env perl
use v5.36;
use warnings;
use FindBin;
use lib "$FindBin::Bin";

# 第3回: Chain of Responsibilityによるコマンド処理
# ハンドラチェーンでコマンドを順番に処理

use MoveHandler;
use ExamineHandler;
use HelpHandler;

package TalkHandler {
    use Moo;
    with 'CommandHandler';

    my %NPCS      = ('古い小屋' => '老人');
    my %DIALOGUES = ('老人'   => '老人「北の泉を越えた先に宝物庫がある。鍵を持っていれば入れるじゃろう。」',);

    sub can_handle($self, $context, $command) {
        return $command eq '話す';
    }

    sub handle($self, $context, $command) {
        my $npc = $NPCS{$context->{location}};
        if ($npc) {
            $context->{talked}{$npc} //= 0;
            if (!$context->{talked}{$npc}) {
                $context->{talked}{$npc} = 1;
                return {handled => 1, message => $DIALOGUES{$npc}};
            }
            return {handled => 1, message => "${npc}はもう話すことがないようだ。"};
        }
        return {handled => 1, message => 'ここには話せる相手がいない。'};
    }
}

package UseItemHandler {
    use Moo;
    with 'CommandHandler';

    sub can_handle($self, $context, $command) {
        return $command =~ /^使う\s+/;
    }

    sub handle($self, $context, $command) {
        my ($item_name) = $command =~ /^使う\s+(.+)$/;
        my $inventory   = $context->{inventory} //= [];

        my $idx = -1;
        for my $i (0 .. $#$inventory) {
            if ($inventory->[$i] eq $item_name) {
                $idx = $i;
                last;
            }
        }

        return {handled => 1, message => 'そのアイテムは持っていない。'} if $idx < 0;

        if ($item_name eq '古びた鍵' && $context->{location} eq '泉') {
            splice(@$inventory, $idx, 1);
            $context->{unlocked}{'宝物庫'} = 1;
            return {handled => 1, message => '古びた鍵を使った。宝物庫への道が開いた！'};
        }
        elsif ($item_name eq '回復薬') {
            splice(@$inventory, $idx, 1);
            $context->{hp} = ($context->{hp} // 100) + 30;
            $context->{hp} = 100 if $context->{hp} > 100;
            return {handled => 1, message => '回復薬を使った。HP: ' . $context->{hp}};
        }

        return {handled => 1, message => 'ここでは使えない。'};
    }
}

package InventoryHandler {
    use Moo;
    with 'CommandHandler';

    sub can_handle($self, $context, $command) {
        return $command eq '持ち物';
    }

    sub handle($self, $context, $command) {
        my @items = @{$context->{inventory} // []};
        return {
            handled => 1,
            message => @items ? '持ち物: ' . join(', ', @items) : '何も持っていない。',
        };
    }
}

package QuitHandler {
    use Moo;
    with 'CommandHandler';

    sub can_handle($self, $context, $command) {
        return $command eq '終了';
    }

    sub handle($self, $context, $command) {
        $context->{running} = 0;
        return {handled => 1, message => 'ゲームを終了します。'};
    }
}

package ChainGame {
    use Moo;

    has context => (
        is      => 'ro',
        default => sub {
            {
                location  => '森の入り口',
                hp        => 100,
                inventory => [],
                talked    => {},
                unlocked  => {},
                running   => 1,
            }
        },
    );

    has handler_chain => (is => 'lazy');

    sub _build_handler_chain($self) {

        # ハンドラチェーンを構築
        my $move      = MoveHandler->new;
        my $examine   = ExamineHandler->new;
        my $talk      = TalkHandler->new;
        my $use_item  = UseItemHandler->new;
        my $inventory = InventoryHandler->new;
        my $help      = HelpHandler->new;
        my $quit      = QuitHandler->new;

        # チェーンをつなげる
        $move->set_next($examine)->set_next($talk)->set_next($use_item)->set_next($inventory)->set_next($help)->set_next($quit);

        return $move;    # チェーンの先頭を返す
    }

    sub describe_location($self) {
        my %descriptions = (
            '森の入り口' => '薄暗い森の入り口に立っている。北に小道が続いている。',
            '小道'    => '木々に囲まれた小道。東に古い小屋、北には泉がある。',
            '古い小屋'  => '朽ちかけた小屋。老人がいる。',
            '泉'     => '澄んだ水の泉。北に扉がある。',
            '宝物庫'   => '金銀財宝が眠る部屋。冒険のゴールだ！',
        );
        return $descriptions{$self->context->{location}} // '見知らぬ場所にいる。';
    }

    sub process_command($self, $command) {

        # コマンドをハンドラチェーンに渡す
        return $self->handler_chain->process($self->context, $command);
    }

    sub run($self) {
        say '=== タイムトラベル冒険ゲーム（Chain of Responsibility版） ===';
        say '';

        while ($self->context->{running}) {
            say 'HP: ' . $self->context->{hp} . '/100';
            say '現在地: ' . $self->context->{location};
            say $self->describe_location();
            print '> ';
            my $input = <STDIN>;
            chomp($input);
            my $result = $self->process_command($input);
            say $result->{message};
            say '';

            if ($self->context->{location} eq '宝物庫') {
                say 'おめでとう！冒険クリア！';
                $self->context->{running} = 0;
            }
        }
    }
}

unless (caller) {
    my $game = ChainGame->new;
    $game->run;
}

1;

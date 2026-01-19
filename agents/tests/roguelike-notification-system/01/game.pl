#!/usr/bin/env perl
# 言語: perl
# バージョン: 5.36以上
# 依存: Moo（cpanmでインストール）

use v5.36;

package GameEvent {
    use Moo;
    use v5.36;

    has 'type' => (
        is       => 'ro',
        required => 1,
    );

    has 'message' => (
        is       => 'ro',
        required => 1,
    );

    has 'timestamp' => (
        is      => 'ro',
        default => sub { time() },
    );
}

package Game {
    use Moo;
    use v5.36;

    has 'player_name' => (
        is       => 'ro',
        required => 1,
    );

    sub defeat_enemy ($self, $enemy_name) {
        my $event = GameEvent->new(
            type    => 'enemy_defeated',
            message => "${enemy_name}を倒した！",
        );
        say "[LOG] " . $self->player_name . ": " . $event->message;
    }

    sub acquire_item ($self, $item_name) {
        my $event = GameEvent->new(
            type    => 'item_acquired',
            message => "${item_name}を手に入れた！",
        );
        say "[LOG] " . $self->player_name . ": " . $event->message;
    }

    sub level_up ($self, $new_level) {
        my $event = GameEvent->new(
            type    => 'level_up',
            message => "レベルが${new_level}になった！",
        );
        say "[LOG] " . $self->player_name . ": " . $event->message;
    }
}

package main {
    use v5.36;

    my $game = Game->new(player_name => '勇者');

    say "=== ダンジョン探索開始 ===";
    say "";

    $game->defeat_enemy('スライム');
    $game->acquire_item('薬草');
    $game->defeat_enemy('ゴブリン');
    $game->level_up(2);
    $game->defeat_enemy('オーク');

    say "";
    say "=== ダンジョン探索終了 ===";
}

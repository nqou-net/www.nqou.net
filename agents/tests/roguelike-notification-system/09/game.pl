#!/usr/bin/env perl
# 言語: perl
# バージョン: 5.36以上
# 依存: Moo（cpanmでインストール）

use v5.36;

# ===================================
# イベントクラス
# ===================================
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

    has 'data' => (
        is      => 'ro',
        default => sub { {} },
    );
}

# ===================================
# Observerインターフェース
# ===================================
package GameEventObserver {
    use Moo::Role;
    use v5.36;

    requires 'update';
}

# ===================================
# 各Observer実装
# ===================================
package LogObserver {
    use Moo;
    use v5.36;

    with 'GameEventObserver';

    sub update ($self, $event) {
        say "[LOG] " . $event->message;
    }
}

package AchievementObserver {
    use Moo;
    use v5.36;

    with 'GameEventObserver';

    has 'unlocked' => (
        is      => 'ro',
        default => sub { [] },
    );

    has 'defeated_count' => (
        is      => 'rw',
        default => 0,
    );

    has 'item_count' => (
        is      => 'rw',
        default => 0,
    );

    sub update ($self, $event) {
        my $type = $event->type;

        if ($type eq 'enemy_defeated') {
            my $count = $self->defeated_count + 1;
            $self->defeated_count($count);

            $self->_check_achievement($count, 1, 'はじめての勝利');
            $self->_check_achievement($count, 5, 'ハンター見習い');
            $self->_check_achievement($count, 10, 'ハンター');
        }
        elsif ($type eq 'item_acquired') {
            my $count = $self->item_count + 1;
            $self->item_count($count);

            $self->_check_achievement($count, 1, 'コレクター見習い');
            $self->_check_achievement($count, 5, 'コレクター');
        }
        elsif ($type eq 'level_up') {
            my $level = $event->data->{level} // 0;
            $self->_check_achievement($level, 3, '成長中');
            $self->_check_achievement($level, 5, '一人前');
        }
    }

    sub _check_achievement ($self, $current, $target, $name) {
        if ($current == $target) {
            push @{$self->unlocked}, $name;
            say "[ACHIEVEMENT] ★ 実績解除: $name ★";
        }
    }

    sub show_achievements ($self) {
        if (@{$self->unlocked}) {
            say "";
            say "☆ 解除した実績 ☆";
            say "  - $_" for @{$self->unlocked};
        } else {
            say "";
            say "まだ実績を解除していません";
        }
    }
}

package SoundObserver {
    use Moo;
    use v5.36;

    with 'GameEventObserver';

    has 'enabled' => (
        is      => 'rw',
        default => 1,
    );

    has 'sound_map' => (
        is      => 'ro',
        default => sub {{
            enemy_defeated => '♪ ジャン！',
            item_acquired  => '♪ キラリン！',
            level_up       => '♪ ファンファーレ！',
        }},
    );

    sub update ($self, $event) {
        return unless $self->enabled;

        my $type = $event->type;
        my $sound = $self->sound_map->{$type};

        if ($sound) {
            say "[SOUND] $sound";
        }
    }
}

package StatisticsObserver {
    use Moo;
    use v5.36;

    with 'GameEventObserver';

    has 'stats' => (
        is      => 'ro',
        default => sub {{
            enemy_defeated => 0,
            item_acquired  => 0,
            level_up       => 0,
        }},
    );

    sub update ($self, $event) {
        my $type = $event->type;

        if (exists $self->stats->{$type}) {
            $self->stats->{$type}++;
        }
    }

    sub show_stats ($self) {
        say "";
        say "┌─────────────────────┐";
        say "│    探索統計         │";
        say "├─────────────────────┤";
        say "│ 敵撃破数:     " . sprintf("%5d", $self->stats->{enemy_defeated}) . " │";
        say "│ アイテム取得: " . sprintf("%5d", $self->stats->{item_acquired}) . " │";
        say "│ レベルアップ: " . sprintf("%5d", $self->stats->{level_up}) . " │";
        say "└─────────────────────┘";
    }
}

# ===================================
# イベントエミッター
# ===================================
package GameEventEmitter {
    use Moo;
    use v5.36;

    has 'observers' => (
        is      => 'ro',
        default => sub { [] },
    );

    sub attach ($self, $observer) {
        unless ($observer->does('GameEventObserver')) {
            die "Error: ObserverはGameEventObserverを実装している必要があります";
        }
        push @{$self->observers}, $observer;
    }

    sub detach ($self, $observer) {
        @{$self->observers} = grep { $_ != $observer } @{$self->observers};
    }

    sub notify ($self, $event) {
        for my $observer (@{$self->observers}) {
            $observer->update($event);
        }
    }
}

# ===================================
# ゲームメインクラス
# ===================================
package DungeonGame {
    use Moo;
    use v5.36;

    has 'emitter' => (
        is      => 'ro',
        default => sub { GameEventEmitter->new() },
    );

    has 'log_observer' => (
        is      => 'ro',
        default => sub { LogObserver->new() },
    );

    has 'achievement_observer' => (
        is      => 'ro',
        default => sub { AchievementObserver->new() },
    );

    has 'sound_observer' => (
        is      => 'ro',
        default => sub { SoundObserver->new() },
    );

    has 'statistics_observer' => (
        is      => 'ro',
        default => sub { StatisticsObserver->new() },
    );

    has 'player_level' => (
        is      => 'rw',
        default => 1,
    );

    has 'enemies' => (
        is      => 'ro',
        default => sub { ['スライム', 'ゴブリン', 'オーク', 'トロル', 'ドラゴン'] },
    );

    has 'items' => (
        is      => 'ro',
        default => sub { ['薬草', 'ポーション', '宝箱', '魔法の剣', '古代の鍵'] },
    );

    sub BUILD ($self, $args) {
        $self->emitter->attach($self->log_observer);
        $self->emitter->attach($self->achievement_observer);
        $self->emitter->attach($self->sound_observer);
        $self->emitter->attach($self->statistics_observer);
    }

    sub defeat_random_enemy ($self) {
        my @enemies = @{$self->enemies};
        my $enemy = $enemies[rand @enemies];

        my $event = GameEvent->new(
            type    => 'enemy_defeated',
            message => "${enemy}を倒した！",
        );
        $self->emitter->notify($event);

        if (rand() < 0.3) {
            $self->level_up();
        }
    }

    sub find_random_item ($self) {
        my @items = @{$self->items};
        my $item = $items[rand @items];

        my $event = GameEvent->new(
            type    => 'item_acquired',
            message => "${item}を手に入れた！",
        );
        $self->emitter->notify($event);
    }

    sub level_up ($self) {
        my $new_level = $self->player_level + 1;
        $self->player_level($new_level);

        my $event = GameEvent->new(
            type    => 'level_up',
            message => "レベルが${new_level}になった！",
            data    => { level => $new_level },
        );
        $self->emitter->notify($event);
    }

    sub toggle_sound ($self) {
        my $current = $self->sound_observer->enabled;
        $self->sound_observer->enabled(!$current);
        say $current ? "[SETTINGS] サウンドをOFFにしました" : "[SETTINGS] サウンドをONにしました";
    }

    sub show_results ($self) {
        $self->statistics_observer->show_stats();
        $self->achievement_observer->show_achievements();
    }
}

# ===================================
# メイン処理（対話型）
# ===================================
package main {
    use v5.36;

    say "╔═══════════════════════════════════════════╗";
    say "║   ローグライク・ダンジョン探索ゲーム      ║";
    say "║   〜通知システムデモ〜                    ║";
    say "╚═══════════════════════════════════════════╝";
    say "";
    say "コマンド:";
    say "  1: 敵を倒す";
    say "  2: アイテムを探す";
    say "  3: サウンドON/OFF";
    say "  4: 結果を表示";
    say "  q: 終了";
    say "";

    my $game = DungeonGame->new();

    while (1) {
        print "> ";
        my $input = <STDIN>;
        chomp $input;

        if ($input eq '1') {
            $game->defeat_random_enemy();
        }
        elsif ($input eq '2') {
            $game->find_random_item();
        }
        elsif ($input eq '3') {
            $game->toggle_sound();
        }
        elsif ($input eq '4') {
            $game->show_results();
        }
        elsif ($input eq 'q') {
            say "";
            say "=== ゲーム終了 ===";
            $game->show_results();
            last;
        }
        else {
            say "不明なコマンド: $input";
        }

        say "";
    }
}

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

    has 'data' => (
        is      => 'ro',
        default => sub { {} },
    );
}

package GameEventObserver {
    use Moo::Role;
    use v5.36;

    requires 'update';
}

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

    sub update ($self, $event) {
        my $type = $event->type;

        if ($type eq 'enemy_defeated') {
            my $count = $self->defeated_count + 1;
            $self->defeated_count($count);

            if ($count == 1) {
                $self->_unlock('はじめての勝利');
            }
            if ($count == 5) {
                $self->_unlock('ハンター見習い');
            }
        }
    }

    sub _unlock ($self, $name) {
        push @{$self->unlocked}, $name;
        say "[ACHIEVEMENT] 実績解除: $name";
    }
}

package SoundObserver {
    use Moo;
    use v5.36;

    with 'GameEventObserver';

    has 'sound_map' => (
        is      => 'ro',
        default => sub {{
            enemy_defeated => 'victory.wav',
            item_acquired  => 'pickup.wav',
            level_up       => 'levelup.wav',
        }},
    );

    sub update ($self, $event) {
        my $type = $event->type;
        my $sound = $self->sound_map->{$type};

        if ($sound) {
            say "[SOUND] $sound を再生";
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
        say "=== 探索統計 ===";
        say "敵撃破数: " . $self->stats->{enemy_defeated};
        say "アイテム取得数: " . $self->stats->{item_acquired};
        say "レベルアップ回数: " . $self->stats->{level_up};
    }
}

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

package main {
    use v5.36;

    my $emitter = GameEventEmitter->new();

    my $log_observer = LogObserver->new();
    my $achievement_observer = AchievementObserver->new();
    my $sound_observer = SoundObserver->new();
    my $statistics_observer = StatisticsObserver->new();

    $emitter->attach($log_observer);
    $emitter->attach($achievement_observer);
    $emitter->attach($sound_observer);
    $emitter->attach($statistics_observer);

    say "=== ダンジョン探索開始 ===";
    say "";

    my @events = (
        GameEvent->new(type => 'enemy_defeated', message => 'スライムを倒した！'),
        GameEvent->new(type => 'item_acquired', message => '薬草を手に入れた！'),
        GameEvent->new(type => 'enemy_defeated', message => 'ゴブリンを倒した！'),
        GameEvent->new(type => 'enemy_defeated', message => 'オークを倒した！'),
        GameEvent->new(type => 'level_up', message => 'レベルが2になった！'),
        GameEvent->new(type => 'item_acquired', message => '宝箱を手に入れた！'),
        GameEvent->new(type => 'enemy_defeated', message => 'トロルを倒した！'),
        GameEvent->new(type => 'enemy_defeated', message => 'ドラゴンを倒した！'),
    );

    for my $event (@events) {
        $emitter->notify($event);
        say "";
    }

    say "=== ダンジョン探索終了 ===";

    $statistics_observer->show_stats();

    say "";
    say "=== 解除した実績 ===";
    say "- $_" for @{$achievement_observer->unlocked};
}

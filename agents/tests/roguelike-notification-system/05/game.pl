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

    has 'prefix' => (
        is      => 'ro',
        default => '[LOG]',
    );

    sub update ($self, $event) {
        say $self->prefix . " " . $event->message;
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
            if ($count == 10) {
                $self->_unlock('ハンター');
            }
        }
        elsif ($type eq 'level_up') {
            my $level = $event->data->{level} // 0;
            if ($level == 5) {
                $self->_unlock('成長');
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

package GameEventEmitter {
    use Moo;
    use v5.36;

    has 'observers' => (
        is      => 'ro',
        default => sub { [] },
    );

    sub attach ($self, $observer) {
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

    $emitter->attach($log_observer);
    $emitter->attach($achievement_observer);
    $emitter->attach($sound_observer);

    say "=== ダンジョン探索開始 ===";
    say "";

    my @events = (
        GameEvent->new(
            type    => 'enemy_defeated',
            message => 'スライムを倒した！',
        ),
        GameEvent->new(
            type    => 'item_acquired',
            message => '薬草を手に入れた！',
        ),
        GameEvent->new(
            type    => 'level_up',
            message => 'レベルが5になった！',
            data    => { level => 5 },
        ),
    );

    for my $event (@events) {
        $emitter->notify($event);
        say "";
    }

    say "=== 解除した実績 ===";
    say "- $_" for @{$achievement_observer->unlocked};
}

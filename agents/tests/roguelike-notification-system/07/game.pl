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

    sub update ($self, $event) {
        say "[SOUND] ♪ サウンドエフェクト再生";
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

    $emitter->attach($log_observer);
    $emitter->attach($achievement_observer);
    $emitter->attach($sound_observer);

    say "=== ダンジョン探索 ===";
    say "";

    my $event = GameEvent->new(
        type    => 'enemy_defeated',
        message => 'スライムを倒した！',
    );

    $emitter->notify($event);
}

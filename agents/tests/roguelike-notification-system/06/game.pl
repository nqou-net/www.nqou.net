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

package GameSettings {
    use Moo;
    use v5.36;

    has 'emitter' => (
        is       => 'ro',
        required => 1,
    );

    has 'sound_observer' => (
        is      => 'ro',
        default => sub { SoundObserver->new() },
    );

    has 'sound_enabled' => (
        is      => 'rw',
        default => 0,
    );

    sub toggle_sound ($self) {
        if ($self->sound_enabled) {
            $self->emitter->detach($self->sound_observer);
            $self->sound_enabled(0);
            say "[SETTINGS] サウンドをOFFにしました";
        } else {
            $self->emitter->attach($self->sound_observer);
            $self->sound_enabled(1);
            say "[SETTINGS] サウンドをONにしました";
        }
    }
}

package main {
    use v5.36;

    my $emitter = GameEventEmitter->new();

    my $log_observer = LogObserver->new();
    $emitter->attach($log_observer);

    my $settings = GameSettings->new(emitter => $emitter);

    say "=== ダンジョン探索開始 ===";
    say "";

    my $event1 = GameEvent->new(
        type    => 'enemy_defeated',
        message => 'スライムを倒した！',
    );
    $emitter->notify($event1);

    say "";
    $settings->toggle_sound();
    say "";

    my $event2 = GameEvent->new(
        type    => 'enemy_defeated',
        message => 'ゴブリンを倒した！',
    );
    $emitter->notify($event2);

    say "";
    $settings->toggle_sound();
    say "";

    my $event3 = GameEvent->new(
        type    => 'enemy_defeated',
        message => 'オークを倒した！',
    );
    $emitter->notify($event3);
}

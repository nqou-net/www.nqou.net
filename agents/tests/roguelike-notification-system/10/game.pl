#!/usr/bin/env perl
# 言語: perl
# バージョン: 5.36以上
# 依存: Moo（cpanmでインストール）

use v5.36;

# 第10回では、Observerパターンの説明が中心で実行可能なコードは少ないため、
# 第9回のコードを使って、パターン構造を示すコメント付きバージョンを作成します

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

# Observer インターフェース（GoFのObserverパターンのObserver）
package GameEventObserver {
    use Moo::Role;
    use v5.36;

    requires 'update';
}

# Concrete Observerの実装例
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

# Subject（Observable）の実装
# GoFのObserverパターンのSubjectに相当
package GameEventEmitter {
    use Moo;
    use v5.36;

    has 'observers' => (
        is      => 'ro',
        default => sub { [] },
    );

    # Observerを登録（attach）
    sub attach ($self, $observer) {
        unless ($observer->does('GameEventObserver')) {
            die "Error: ObserverはGameEventObserverを実装している必要があります";
        }
        push @{$self->observers}, $observer;
    }

    # Observerを削除（detach）
    sub detach ($self, $observer) {
        @{$self->observers} = grep { $_ != $observer } @{$self->observers};
    }

    # 全Observerに通知（notify）
    sub notify ($self, $event) {
        for my $observer (@{$self->observers}) {
            $observer->update($event);
        }
    }
}

package main {
    use v5.36;

    say "=== Observerパターンのデモ ===";
    say "";
    say "Subject（GameEventEmitter）が状態変化を";
    say "Observers（LogObserver、AchievementObserver）に通知します";
    say "";

    # Subjectを作成
    my $emitter = GameEventEmitter->new();

    # Concrete Observerを作成
    my $log_observer = LogObserver->new();
    my $achievement_observer = AchievementObserver->new();

    # Observerを登録（attach）
    $emitter->attach($log_observer);
    $emitter->attach($achievement_observer);

    say "=== イベント発生 ===";
    say "";

    # Subjectが状態変化を通知（notify）
    my $event = GameEvent->new(
        type    => 'enemy_defeated',
        message => 'スライムを倒した！',
    );

    # 一回の通知で全Observerに伝わる（これがObserverパターンの核心）
    $emitter->notify($event);

    say "";
    say "=== Observerパターンのメリット ===";
    say "- Subjectは具体的なObserverを知らなくていい（疎結合）";
    say "- 新しいObserverを簡単に追加できる（開放閉鎖原則）";
    say "- 実行時にObserverを追加・削除できる（動的管理）";
}

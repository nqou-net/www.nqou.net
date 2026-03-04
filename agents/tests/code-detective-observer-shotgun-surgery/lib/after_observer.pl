#!/usr/bin/env perl
use v5.34;
use warnings;
use utf8;
use feature 'signatures';
no warnings "experimental::signatures";

# ==============================================================================
# After: Observer パターンを適用し、Shotgun Surgery を解消した例
#
# StockManager（Subject）は「在庫が変わった」ことを通知するだけ。
# 誰がどう反応するかは各 Observer の責任。
# 新しい通知手段の追加は Observer を1つ作って登録するだけで済む。
# ==============================================================================

# ----------------------------------
# 1. Observer Role（共通インターフェース）
# ----------------------------------
package StockObserver::Role {
    use Moo::Role;
    requires 'on_stock_updated';
}

# ----------------------------------
# 2. 具体的な Observer 群
# ----------------------------------
package StockObserver::Email {
    use Moo;
    with 'StockObserver::Role';

    sub on_stock_updated ($self, $item, $quantity) {
        return "[EMAIL] $item is now $quantity";
    }
}

package StockObserver::Logger {
    use Moo;
    with 'StockObserver::Role';

    sub on_stock_updated ($self, $item, $quantity) {
        return "[LOG] $item: quantity changed to $quantity";
    }
}

package StockObserver::Dashboard {
    use Moo;
    with 'StockObserver::Role';

    sub on_stock_updated ($self, $item, $quantity) {
        return "[DASHBOARD] Refreshed: $item ($quantity)";
    }
}

# ----------------------------------
# 3. Subject（通知の発信元）
# ----------------------------------
package StockManager {
    use Moo;

    has observers => (
        is      => 'ro',
        default => sub { [] },
    );

    sub add_observer ($self, $observer) {
        die "Invalid observer" unless $observer->DOES('StockObserver::Role');
        push @{$self->observers}, $observer;
        return $self;  # メソッドチェーン用
    }

    sub remove_observer ($self, $observer) {
        @{$self->observers} = grep { $_ != $observer } @{$self->observers};
        return $self;
    }

    sub notify ($self, $item, $quantity) {
        my @results;
        for my $obs (@{$self->observers}) {
            push @results, $obs->on_stock_updated($item, $quantity);
        }
        return @results;
    }

    sub update_stock ($self, $item, $quantity) {
        # 在庫の更新（ここではシミュレーション）
        my $message = "Stock updated: $item => $quantity";

        # Observer への通知 — これだけ！
        my @notifications = $self->notify($item, $quantity);

        return {
            message       => $message,
            notifications => \@notifications,
        };
    }
}

# 動作確認
if (!caller) {
    my $manager = StockManager->new;

    # Observer を登録
    $manager->add_observer(StockObserver::Email->new);
    $manager->add_observer(StockObserver::Logger->new);
    $manager->add_observer(StockObserver::Dashboard->new);

    my $result = $manager->update_stock('Keyboard', 150);

    say $result->{message};
    say $_ for @{$result->{notifications}};
}

1;

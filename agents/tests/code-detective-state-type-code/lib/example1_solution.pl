#!/usr/bin/env perl
use v5.34;
use warnings;
use utf8;
use feature 'signatures';
no warnings "experimental::signatures";

# ------------------------------
# 1. 状態の共通インターフェース (Role)
# ------------------------------
package OrderState::Role {
    use Moo::Role;
    requires 'pay';
    requires 'ship';
    requires 'cancel';
}

# ------------------------------
# 2. 具体的な状態(State)群
# ------------------------------

# 未決済 (Unpaid)
package OrderState::Unpaid {
    use Moo;
    with 'OrderState::Role';

    sub pay ($self, $order) {
        push @{$order->output}, "Order paid.";
        $order->change_state(OrderState::Preparing->new);
    }
    sub ship ($self, $order) {
        push @{$order->output}, "Cannot ship: Not paid yet.";
    }
    sub cancel ($self, $order) {
        push @{$order->output}, "Order cancelled.";
        $order->change_state(OrderState::Cancelled->new);
    }
}

# 準備中 (Preparing)
package OrderState::Preparing {
    use Moo;
    with 'OrderState::Role';

    sub pay ($self, $order) {
        push @{$order->output}, "Already paid.";
    }
    sub ship ($self, $order) {
        push @{$order->output}, "Order shipped.";
        $order->change_state(OrderState::Shipped->new);
    }
    sub cancel ($self, $order) {
        push @{$order->output}, "Order cancelled and refunded.";
        $order->change_state(OrderState::Cancelled->new);
    }
}

# 発送済 (Shipped)
package OrderState::Shipped {
    use Moo;
    with 'OrderState::Role';

    sub pay ($self, $order) {
        push @{$order->output}, "Already shipped.";
    }
    sub ship ($self, $order) {
        push @{$order->output}, "Already shipped.";
    }
    sub cancel ($self, $order) {
        push @{$order->output}, "Cannot cancel: Already shipped.";
    }
}

# キャンセル (Cancelled)
package OrderState::Cancelled {
    use Moo;
    with 'OrderState::Role';

    sub pay ($self, $order) {
        push @{$order->output}, "Cannot pay: Order is cancelled.";
    }
    sub ship ($self, $order) {
        push @{$order->output}, "Cannot ship: Order is cancelled.";
    }
    sub cancel ($self, $order) {
        push @{$order->output}, "Already cancelled.";
    }
}

# ------------------------------
# 3. Context（メインロジック）
# ------------------------------
package SmartOrder {
    use Moo;

    # ステータスの代わりに「状態オブジェクト」を保持する
    has state => (
        is      => 'rw',
        default => sub { OrderState::Unpaid->new },
    );

    has output => (
        is      => 'ro',
        default => sub { [] },
    );

    # 状態の変更を内部で許可するメソッド
    # （実際の業務ではアクセサ制限やカプセル化を行うことも多い）
    sub change_state ($self, $new_state) {
        $self->state($new_state);
    }

    # 各アクションは、現在の状態オブジェクトに「自分自身($self)」を添えて委譲する
    sub pay ($self) {
        $self->state->pay($self);
        return $self;
    }

    sub ship ($self) {
        $self->state->ship($self);
        return $self;
    }

    sub cancel ($self) {
        $self->state->cancel($self);
        return $self;
    }
}
1;

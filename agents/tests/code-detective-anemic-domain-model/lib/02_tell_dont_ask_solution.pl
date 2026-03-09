#!/usr/bin/env perl
use v5.36;
use warnings;

# --- After（Tell, Don't Ask） ---

package Order {
    use Moo;
    # データ（プロパティ）を隠蔽するか、読み取り専用にする
    has _amount => (is => 'ro', init_arg => 'amount');
    has _user_type => (is => 'ro', init_arg => 'user_type');

    # 自分自身の状態を使って計算する（振る舞いを持つ）
    sub calculate_total ($self) {
        return $self->_amount - $self->_calculate_discount;
    }

    sub _calculate_discount ($self) {
        return 0 unless $self->_user_type eq 'premium';
        return $self->_amount >= 10000 ? $self->_amount * 0.15 : $self->_amount * 0.05;
    }
}

package OrderService {
    use Moo;

    sub process_order ($self, $order) {
        # オブジェクトに「計算しろ（Tell）」と命じるだけ。中は見ない（Don't Ask）
        my $total = $order->calculate_total;
        # 決済処理など他のフローへ続く... (ここでは単に返すだけ)
        return $total;
    }
}

1;

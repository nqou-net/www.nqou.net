#!/usr/bin/env perl
use v5.36;
use warnings;

# --- Before（貧弱なドメインモデル） ---

package Order {
    use Moo;
    # ゲッター/セッターしかない「全裸の」データクラス
    has amount => (is => 'rw');
    has user_type => (is => 'rw'); # 'normal', 'premium'
}

package OrderService {
    use Moo;

    sub calculate_total ($self, $order) {
        # データをひん剥いて（getして）外部で計算している
        my $amount = $order->amount;
        my $user_type = $order->user_type;
        
        my $discount = 0;
        if ($user_type eq 'premium') {
            if ($amount >= 10000) {
                $discount = $amount * 0.15;
            } else {
                $discount = $amount * 0.05;
            }
        }
        
        return $amount - $discount;
    }
}

1;

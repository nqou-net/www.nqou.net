use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

# === Before: Hardcoded Business Rules ===
# 割引ルールが巨大な if/elsif チェーンにハードコードされている。
# 新しいルールを追加するたびに既存の条件分岐を改修する必要がある。

package Order {
    use Moo;
    use Types::Standard qw(Num Bool Int);

    has total      => (is => 'ro', isa => Num,  required => 1);
    has is_member  => (is => 'ro', isa => Bool, default  => 0);
    has item_count => (is => 'ro', isa => Int,  default  => 1);
}

package DiscountCalculator {
    use Moo;

    sub calculate ($self, $order) {
        # 会員かつ1万円以上 → 15%
        if ($order->total >= 10000 && $order->is_member) {
            return 0.15;
        }
        # 1万円以上（非会員） → 10%
        elsif ($order->total >= 10000) {
            return 0.10;
        }
        # 会員かつ5点以上 → 8%
        elsif ($order->is_member && $order->item_count >= 5) {
            return 0.08;
        }
        # 3点以上 → 5%
        elsif ($order->item_count >= 3) {
            return 0.05;
        }

        return 0;
    }
}

1;

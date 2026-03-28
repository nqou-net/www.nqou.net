use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

# === Before: Scattered Conditions（条件分岐の散在・重複） ===
# 会員ランク判定やキャンペーン判定が複数メソッドに散在し、
# 条件の組み合わせ追加のたびに修正箇所が増えてバグが混入する。

# --- Order（注文データ） ---
package Order {
    use Moo;
    has member_rank       => (is => 'ro', required => 1);
    has total             => (is => 'ro', required => 1);
    has is_campaign_period => (is => 'ro', default => 0);
}

# --- DiscountService（アンチパターン: 条件が散在） ---
package DiscountService {
    use Moo;

    sub calculate_discount ($self, $order) {
        my $discount = 0;

        # 会員ランク割引
        if ($order->member_rank eq 'gold') {
            $discount += $order->total * 0.10;
        } elsif ($order->member_rank eq 'silver') {
            $discount += $order->total * 0.05;
        }

        # 期間限定キャンペーン
        if ($order->is_campaign_period && $order->total >= 5000) {
            $discount += 500;
        }

        # 組み合わせ割引（ゴールド会員 × キャンペーン × 1万円以上）
        if ($order->member_rank eq 'gold'
            && $order->is_campaign_period
            && $order->total >= 10000) {
            $discount += 1000;
        }

        return $discount;
    }

    sub is_free_shipping ($self, $order) {
        # 送料無料条件（ゴールド会員 or 5000円以上）
        if ($order->member_rank eq 'gold') {
            return 1;
        }
        if ($order->total >= 5000) {
            return 1;
        }
        return 0;
    }

    sub calculate_points ($self, $order) {
        my $points = int($order->total * 0.01);

        # ゴールド会員はポイント2倍
        if ($order->member_rank eq 'gold') {
            $points *= 2;
        }

        # キャンペーン中はさらにボーナス
        if ($order->is_campaign_period) {
            $points += 100;
        }

        return $points;
    }
}

1;

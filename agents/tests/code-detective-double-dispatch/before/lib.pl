use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

# === Before: Type Checking Chains（型チェックの連鎖） ===
# 注文種別と決済方法の組み合わせを ref() で二重にチェックし、
# 9分岐を一つのメソッドに集中させている。

# --- 注文クラス群 ---
package NormalOrder {
    use Moo;
    has total => (is => 'ro', required => 1);
}

package SubscriptionOrder {
    use Moo;
    has monthly_amount => (is => 'ro', required => 1);
}

package PreOrder {
    use Moo;
    has total   => (is => 'ro', required => 1);
    has deposit => (is => 'ro', required => 1);
}

# --- 決済クラス群 ---
package CreditCard {
    use Moo;
}

package BankTransfer {
    use Moo;
}

package ConvenienceStore {
    use Moo;
}

# --- PaymentProcessor（アンチパターン: 型チェックの二重ネスト） ---
package PaymentProcessor {
    use Moo;

    sub process ($self, $order, $payment) {
        if (ref $order eq 'NormalOrder') {
            if (ref $payment eq 'CreditCard') {
                return { method => 'credit', amount => $order->total, status => 'charged' };
            } elsif (ref $payment eq 'BankTransfer') {
                return { method => 'bank', amount => $order->total, status => 'pending', due_days => 7 };
            } elsif (ref $payment eq 'ConvenienceStore') {
                return { method => 'convenience', amount => $order->total, status => 'awaiting', expires_in => 3 };
            }
        } elsif (ref $order eq 'SubscriptionOrder') {
            if (ref $payment eq 'CreditCard') {
                return { method => 'credit', amount => $order->monthly_amount, status => 'enrolled', recurring => 1 };
            } elsif (ref $payment eq 'BankTransfer') {
                return { method => 'bank', amount => $order->monthly_amount, status => 'pending', due_days => 14, recurring => 1 };
            } elsif (ref $payment eq 'ConvenienceStore') {
                die "定期購入にコンビニ払いは未対応です\n";
            }
        } elsif (ref $order eq 'PreOrder') {
            if (ref $payment eq 'CreditCard') {
                return { method => 'credit', amount => 0, status => 'authorized', hold => $order->total };
            } elsif (ref $payment eq 'BankTransfer') {
                return { method => 'bank', amount => $order->total, status => 'pending', due_days => 30 };
            } elsif (ref $payment eq 'ConvenienceStore') {
                return { method => 'convenience', amount => $order->deposit, status => 'awaiting', expires_in => 7 };
            }
        }
    }
}

1;

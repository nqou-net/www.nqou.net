use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

# === After: Double Dispatch ===
# 注文が accept_payment で自身の型を名乗り、
# 決済が process_for_* で自身の型に応じた処理を返す。

# --- 注文クラス群（1段目のディスパッチ） ---
package Order::Normal {
    use Moo;
    has total => (is => 'ro', required => 1);

    sub accept_payment ($self, $payment) {
        return $payment->process_for_normal($self);
    }
}

package Order::Subscription {
    use Moo;
    has monthly_amount => (is => 'ro', required => 1);

    sub accept_payment ($self, $payment) {
        return $payment->process_for_subscription($self);
    }
}

package Order::PreOrder {
    use Moo;
    has total   => (is => 'ro', required => 1);
    has deposit => (is => 'ro', required => 1);

    sub accept_payment ($self, $payment) {
        return $payment->process_for_preorder($self);
    }
}

# --- 決済クラス群（2段目のディスパッチ） ---
package Payment::CreditCard {
    use Moo;

    sub process_for_normal ($self, $order) {
        return { method => 'credit', amount => $order->total, status => 'charged' };
    }

    sub process_for_subscription ($self, $order) {
        return { method => 'credit', amount => $order->monthly_amount, status => 'enrolled', recurring => 1 };
    }

    sub process_for_preorder ($self, $order) {
        return { method => 'credit', amount => 0, status => 'authorized', hold => $order->total };
    }
}

package Payment::BankTransfer {
    use Moo;

    sub process_for_normal ($self, $order) {
        return { method => 'bank', amount => $order->total, status => 'pending', due_days => 7 };
    }

    sub process_for_subscription ($self, $order) {
        return { method => 'bank', amount => $order->monthly_amount, status => 'pending', due_days => 14, recurring => 1 };
    }

    sub process_for_preorder ($self, $order) {
        return { method => 'bank', amount => $order->total, status => 'pending', due_days => 30 };
    }
}

package Payment::ConvenienceStore {
    use Moo;

    sub process_for_normal ($self, $order) {
        return { method => 'convenience', amount => $order->total, status => 'awaiting', expires_in => 3 };
    }

    sub process_for_subscription ($self, $order) {
        die "定期購入にコンビニ払いは未対応です\n";
    }

    sub process_for_preorder ($self, $order) {
        return { method => 'convenience', amount => $order->deposit, status => 'awaiting', expires_in => 7 };
    }
}

1;

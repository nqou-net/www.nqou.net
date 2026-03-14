#!/usr/bin/env perl
use v5.34;
use warnings;
use feature 'signatures';
no warnings "experimental::signatures";

package External::PaymentAPI {
    use Moo;
    sub charge ($self, $amount) {
        print "[API] Charged $amount to credit card.\n";
        return 1;
    }
    sub refund ($self, $amount) {
        print "[API] Refunded $amount to credit card.\n";
        return 1;
    }
}

package Database {
    use Moo;
    sub begin_transaction ($self) { print "[DB] BEGIN TRANSACTION\n"; }
    sub commit ($self)            { print "[DB] COMMIT\n"; }
    sub rollback ($self)          { print "[DB] ROLLBACK\n"; }
    sub save_order ($self, $order) {
        if ($order->{should_fail}) {
            die "DB Error: Could not save order!\n";
        }
        print "[DB] Order saved.\n";
        return 1;
    }
}

package OrderProcessor {
    use Moo;
    has api => (is => 'ro', default => sub { External::PaymentAPI->new });
    has db  => (is => 'ro', default => sub { Database->new });

    sub process_order ($self, $order) {
        $self->db->begin_transaction();

        # 1. 外部APIで決済（ここで副作用が発生するがロールバック対象に入らない）
        eval {
            $self->api->charge($order->{amount});
        };
        if ($@) {
            $self->db->rollback();
            die "Payment failed: $@";
        }

        # 2. データベースに注文を保存
        eval {
            $self->db->save_order($order);
        };
        if ($@) {
            # DBはロールバックできるが、APIの決済はそのままになってしまう！
            # お金だけ引き落としてエラー終了する最悪のバグ
            $self->db->rollback();
            die "Order save failed: $@";
        }

        $self->db->commit();
        return 1;
    }
}

1;

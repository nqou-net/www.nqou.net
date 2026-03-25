use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

# === Before: Scattered Writes（散弾銃的DB更新） ===
# OrderRepository, InventoryRepository, PaymentRepository への保存が
# 各々独立して実行される。途中でエラーが起きると「注文だけ保存済み・
# 在庫は未更新」という整合性のない状態が残る。

# --- 共有インメモリストレージ ---
package InMemoryDB {
    use Moo;
    has orders    => (is => 'rw', default => sub { [] });
    has inventory => (is => 'rw', default => sub { +{} });
    has payments  => (is => 'rw', default => sub { [] });
}

# --- OrderRepository ---
package OrderRepository {
    use Moo;
    has _db => (is => 'ro', required => 1);

    sub save ($self, $order) {
        push @{ $self->_db->orders }, $order;
    }

    sub count ($self) { scalar @{ $self->_db->orders } }
}

# --- InventoryRepository ---
package InventoryRepository {
    use Moo;
    has _db   => (is => 'ro', required => 1);
    has _fail => (is => 'rw', default  => 0);   # テスト用: 強制障害フラグ

    sub decrease ($self, $item_id, $qty) {
        die "在庫システム障害\n" if $self->_fail;
        my $stock = $self->_db->inventory->{$item_id} // 0;
        die "在庫不足: $item_id\n" if $stock < $qty;
        $self->_db->inventory->{$item_id} = $stock - $qty;
    }

    sub get_stock ($self, $item_id) { $self->_db->inventory->{$item_id} // 0 }
}

# --- PaymentRepository ---
package PaymentRepository {
    use Moo;
    has _db => (is => 'ro', required => 1);

    sub save ($self, $payment) {
        push @{ $self->_db->payments }, $payment;
    }

    sub count ($self) { scalar @{ $self->_db->payments } }
}

# --- OrderService（アンチパターン: 3つの独立した保存操作） ---
package OrderService {
    use Moo;
    has _order_repo     => (is => 'ro', required => 1);
    has _inventory_repo => (is => 'ro', required => 1);
    has _payment_repo   => (is => 'ro', required => 1);

    sub create_order ($self, %params) {
        my $order = {
            id       => 'ORD-' . ($self->_order_repo->count + 1),
            item_id  => $params{item_id},
            quantity => $params{quantity},
            user_id  => $params{user_id},
        };

        $self->_order_repo->save($order);                              # 1. 注文を保存
        $self->_inventory_repo->decrease(                              # 2. 在庫を減らす
            $params{item_id}, $params{quantity}
        );
        $self->_payment_repo->save({                                   # 3. 支払いを保存
            order_id => $order->{id},
            amount   => $params{amount},
        });

        return $order;
    }
}

1;

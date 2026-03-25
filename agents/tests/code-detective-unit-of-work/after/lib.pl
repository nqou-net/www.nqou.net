use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

# === After: Unit of Work パターン ===
# すべての変更（新規作成・更新）を UnitOfWork に登録し、
# commit() で一括して適用する。途中でエラーが起きれば全変更をロールバック。

# --- 共有インメモリストレージ ---
package InMemoryDB {
    use Moo;
    has orders    => (is => 'rw', default => sub { [] });
    has inventory => (is => 'rw', default => sub { +{} });
    has payments  => (is => 'rw', default => sub { [] });
}

# --- ドメインオブジェクト（insert/update メソッドを持つ） ---

package OrderRecord {
    use Moo;
    has id       => (is => 'ro', required => 1);
    has item_id  => (is => 'ro', required => 1);
    has quantity => (is => 'ro', required => 1);
    has user_id  => (is => 'ro', required => 1);

    sub insert ($self, $db) {
        push @{ $db->orders }, {
            id       => $self->id,
            item_id  => $self->item_id,
            quantity => $self->quantity,
            user_id  => $self->user_id,
        };
    }
}

package InventoryRecord {
    use Moo;
    has item_id         => (is => 'ro', required => 1);
    has new_quantity    => (is => 'rw', required => 1);
    has _fail_on_update => (is => 'rw', default  => 0);  # テスト用: 強制障害フラグ

    sub update ($self, $db) {
        die "在庫システム障害\n" if $self->_fail_on_update;
        $db->inventory->{ $self->item_id } = $self->new_quantity;
    }
}

package PaymentRecord {
    use Moo;
    has order_id => (is => 'ro', required => 1);
    has amount   => (is => 'ro', required => 1);

    sub insert ($self, $db) {
        push @{ $db->payments }, {
            order_id => $self->order_id,
            amount   => $self->amount,
        };
    }
}

# --- Unit of Work ---
package UnitOfWork {
    use Moo;
    use Carp qw(croak);

    has _db            => (is => 'ro', required => 1);
    has _new_objects   => (is => 'ro', default  => sub { [] });
    has _dirty_objects => (is => 'ro', default  => sub { [] });

    sub register_new ($self, $obj) {
        push @{ $self->_new_objects }, $obj;
        return $self;
    }

    sub register_dirty ($self, $obj) {
        push @{ $self->_dirty_objects }, $obj;
        return $self;
    }

    sub commit ($self) {
        my $db = $self->_db;

        # スナップショットを保存（疑似トランザクション）
        my $snapshot = {
            orders    => [ @{ $db->orders } ],
            inventory => { %{ $db->inventory } },
            payments  => [ @{ $db->payments } ],
        };

        eval {
            for my $obj (@{ $self->_new_objects }) {
                $obj->insert($db);
            }
            for my $obj (@{ $self->_dirty_objects }) {
                $obj->update($db);
            }
        };
        if (my $err = $@) {
            # ロールバック: スナップショットを復元
            $db->orders(   $snapshot->{orders}    );
            $db->inventory($snapshot->{inventory} );
            $db->payments( $snapshot->{payments}  );
            croak $err;
        }
    }
}

# --- OrderService（Unit of Work を使った一括コミット） ---
package OrderService {
    use Moo;
    has _db             => (is => 'ro', required => 1);
    has _fail_inventory => (is => 'rw', default  => 0);  # テスト用フラグ

    sub create_order ($self, %params) {
        my $db = $self->_db;

        my $current_stock = $db->inventory->{ $params{item_id} } // 0;
        die "在庫不足: $params{item_id}\n" if $current_stock < $params{quantity};

        my $order = OrderRecord->new(
            id       => 'ORD-' . (scalar(@{ $db->orders }) + 1),
            item_id  => $params{item_id},
            quantity => $params{quantity},
            user_id  => $params{user_id},
        );

        my $inventory = InventoryRecord->new(
            item_id         => $params{item_id},
            new_quantity    => $current_stock - $params{quantity},
            _fail_on_update => $self->_fail_inventory,
        );

        my $payment = PaymentRecord->new(
            order_id => $order->id,
            amount   => $params{amount},
        );

        # すべての変更を Unit of Work に登録し、一括コミット
        my $uow = UnitOfWork->new(_db => $db);
        $uow->register_new($order)
            ->register_dirty($inventory)
            ->register_new($payment)
            ->commit;

        return $order;
    }
}

1;

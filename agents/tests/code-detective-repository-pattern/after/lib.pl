use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

# === After: Repository パターン ===
# Order クラスは純粋なビジネスロジックだけ。
# データアクセスは Repository に分離。テスト時は InMemory 版を注入。

# --- 純粋なドメインモデル（DB依存なし）---
package Order {
    use Moo;
    use Carp qw( croak );

    has id       => ( is => 'rw' );
    has customer => ( is => 'ro', required => 1 );
    has items    => ( is => 'ro', required => 1 );  # [{ name, price, qty }]
    has status   => ( is => 'rw', default  => 'draft' );
    # dbh は不要！

    sub total ($self) {
        my $sum = 0;
        $sum += $_->{price} * $_->{qty} for $self->items->@*;
        return $sum;
    }

    sub confirm ($self) {
        croak "Cannot confirm: status is " . $self->status
            unless $self->status eq 'draft';
        $self->status('confirmed');
        # save() は呼ばない — 永続化は呼び出し側の責務
    }

    sub ship ($self) {
        croak "Cannot ship: status is " . $self->status
            unless $self->status eq 'confirmed';
        $self->status('shipped');
    }

    sub cancel ($self) {
        croak "Cannot cancel: status is " . $self->status
            unless $self->status eq 'draft' || $self->status eq 'confirmed';
        $self->status('cancelled');
    }
}

# --- Repository ロール（インターフェース）---
package OrderRepository {
    use Moo::Role;

    requires 'save';           # ($order) → $order (id付与済み)
    requires 'find_by_id';     # ($id)    → $order | undef
    requires 'search';         # (%criteria) → [$order, ...]
}

# --- 本番用: DBI を使った実装 ---
package DbiOrderRepository {
    use Moo;
    with 'OrderRepository';

    has dbh => ( is => 'ro', required => 1 );

    sub save ($self, $order) {
        my $dbh = $self->dbh;
        if ($order->id) {
            $dbh->do(
                "UPDATE orders SET customer=?, status=?, items=? WHERE id=?",
                $order->customer, $order->status,
                _serialize($order->items), $order->id,
            );
        }
        else {
            $dbh->do(
                "INSERT INTO orders (customer, status, items) VALUES (?, ?, ?)",
                $order->customer, $order->status,
                _serialize($order->items),
            );
            $order->id($dbh->last_insert_id(undef, undef, 'orders', 'id'));
        }
        # FakeDbh用
        $dbh->_insert_raw($order->id, {
            id       => $order->id,
            customer => $order->customer,
            status   => $order->status,
            items    => $order->items,
        }) if $dbh->can('_insert_raw');
        return $order;
    }

    sub find_by_id ($self, $id) {
        my $row = $self->dbh->selectrow_hashref(
            "SELECT * FROM orders WHERE id = ?", undef, $id,
        );
        return undef unless $row;
        return Order->new(
            id       => $row->{id},
            customer => $row->{customer},
            items    => $row->{items},
            status   => $row->{status},
        );
    }

    sub search ($self, %criteria) {
        my $rows = $self->dbh->selectall_arrayref(
            "SELECT * FROM orders WHERE status = ?", { Slice => {} },
            $criteria{status} // 'draft',
        );
        return [ map {
            Order->new(
                id       => $_->{id},
                customer => $_->{customer},
                items    => $_->{items},
                status   => $_->{status},
            )
        } @$rows ];
    }

    sub _serialize ($items) {
        return join(',', map { "$_->{name}:$_->{price}x$_->{qty}" } @$items);
    }
}

# --- テスト用: インメモリ実装 ---
package InMemoryOrderRepository {
    use Moo;
    with 'OrderRepository';

    has _store   => ( is => 'ro', default => sub { {} } );
    has _next_id => ( is => 'rw', default => 1 );

    sub save ($self, $order) {
        unless ($order->id) {
            $order->id($self->_next_id);
            $self->_next_id($self->_next_id + 1);
        }
        # ディープコピーで保存（参照共有を防ぐ）
        $self->_store->{$order->id} = {
            id       => $order->id,
            customer => $order->customer,
            items    => [ map { {%$_} } $order->items->@* ],
            status   => $order->status,
        };
        return $order;
    }

    sub find_by_id ($self, $id) {
        my $data = $self->_store->{$id};
        return undef unless $data;
        return Order->new(
            id       => $data->{id},
            customer => $data->{customer},
            items    => [ map { {%$_} } $data->{items}->@* ],
            status   => $data->{status},
        );
    }

    sub search ($self, %criteria) {
        my @results;
        for my $data (values $self->_store->%*) {
            if ($criteria{status}) {
                next unless $data->{status} eq $criteria{status};
            }
            push @results, Order->new(
                id       => $data->{id},
                customer => $data->{customer},
                items    => [ map { {%$_} } $data->{items}->@* ],
                status   => $data->{status},
            );
        }
        return \@results;
    }

    sub count ($self) { scalar keys $self->_store->%* }
}

# FakeDbh (DbiOrderRepository のテスト用)
package FakeDbh {
    use Moo;
    has _store => ( is => 'ro', default => sub { {} } );
    has _next_id => ( is => 'rw', default => 1 );

    sub do ($self, $sql, @binds) { return 1 }

    sub selectrow_hashref ($self, $sql, $attr, @binds) {
        return $self->_store->{$binds[0]};
    }

    sub selectall_arrayref ($self, $sql, $attr, @binds) {
        my @results;
        for my $row (values $self->_store->%*) {
            if ($binds[0] && $row->{status}) {
                next unless $row->{status} eq $binds[0];
            }
            push @results, $row;
        }
        return \@results;
    }

    sub last_insert_id ($self, @args) { $self->_next_id }

    sub _insert_raw ($self, $id, $data) {
        $self->_store->{$id} = $data;
        my $next = $id + 1;
        $self->_next_id($next) if $next > $self->_next_id;
    }
}

1;

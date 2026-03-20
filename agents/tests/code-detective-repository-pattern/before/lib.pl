use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

# === Before: Fat Model ===
# Order クラスにビジネスロジックとデータアクセスが混在。
# テストには必ず $dbh（DB接続）が必要になる。

package FakeDbh {
    # テスト用の偽DBハンドル（本来は DBI->connect で取得）
    use Moo;
    has _store => ( is => 'ro', default => sub { {} } );
    has _next_id => ( is => 'rw', default => 1 );

    sub do ($self, $sql, @binds) {
        # INSERT/UPDATE をシミュレート
        return 1;
    }

    sub selectrow_hashref ($self, $sql, $attr, @binds) {
        my $id = $binds[0];
        return $self->_store->{$id};
    }

    sub selectall_arrayref ($self, $sql, $attr, @binds) {
        my @results;
        for my $row (values $self->_store->%*) {
            push @results, $row;
        }
        return \@results;
    }

    sub last_insert_id ($self, @args) { $self->_next_id }

    # テスト用ヘルパー: データを直接挿入
    sub _insert_raw ($self, $id, $data) {
        $self->_store->{$id} = $data;
    }
}

package Order {
    use Moo;
    use Carp qw( croak );

    has id         => ( is => 'rw' );
    has customer   => ( is => 'ro', required => 1 );
    has items      => ( is => 'ro', required => 1 );  # [{ name, price, qty }]
    has status     => ( is => 'rw', default  => 'draft' );
    has dbh        => ( is => 'ro', required => 1 );   # ← DB接続が必須！

    # --- ビジネスロジック ---
    sub total ($self) {
        my $sum = 0;
        $sum += $_->{price} * $_->{qty} for $self->items->@*;
        return $sum;
    }

    sub confirm ($self) {
        croak "Cannot confirm: status is " . $self->status
            unless $self->status eq 'draft';
        $self->status('confirmed');
        $self->save();  # ← ビジネスロジックの中で直接 DB に書き込む
    }

    sub ship ($self) {
        croak "Cannot ship: status is " . $self->status
            unless $self->status eq 'confirmed';
        $self->status('shipped');
        $self->save();
    }

    sub cancel ($self) {
        croak "Cannot cancel: status is " . $self->status
            unless $self->status eq 'draft' || $self->status eq 'confirmed';
        $self->status('cancelled');
        $self->save();
    }

    # --- データアクセス（SQL直書き）---
    sub save ($self) {
        my $dbh = $self->dbh;
        if ($self->id) {
            $dbh->do(
                "UPDATE orders SET customer=?, status=?, items=? WHERE id=?",
                $self->customer, $self->status, _serialize_items($self->items), $self->id,
            );
        }
        else {
            $dbh->do(
                "INSERT INTO orders (customer, status, items) VALUES (?, ?, ?)",
                $self->customer, $self->status, _serialize_items($self->items),
            );
            $self->id($dbh->last_insert_id(undef, undef, 'orders', 'id'));
        }
        # DB接続の _store にも反映（FakeDbh用）
        $dbh->_insert_raw($self->id, {
            id       => $self->id,
            customer => $self->customer,
            status   => $self->status,
            items    => $self->items,
        }) if $dbh->can('_insert_raw');
    }

    sub find_by_id ($class, $dbh, $id) {
        my $row = $dbh->selectrow_hashref(
            "SELECT * FROM orders WHERE id = ?", undef, $id,
        );
        return undef unless $row;
        return $class->new(
            id       => $row->{id},
            customer => $row->{customer},
            items    => $row->{items},
            status   => $row->{status},
            dbh      => $dbh,
        );
    }

    sub search ($class, $dbh, %criteria) {
        my $rows = $dbh->selectall_arrayref(
            "SELECT * FROM orders WHERE status = ?", { Slice => {} },
            $criteria{status} // 'draft',
        );
        return [ map {
            $class->new(
                id       => $_->{id},
                customer => $_->{customer},
                items    => $_->{items},
                status   => $_->{status},
                dbh      => $dbh,
            )
        } @$rows ];
    }

    sub _serialize_items ($items) {
        # 本来は JSON::encode_json 等
        return join(',', map { "$_->{name}:$_->{price}x$_->{qty}" } @$items);
    }
}

1;

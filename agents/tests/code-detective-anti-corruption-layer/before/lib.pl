use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

# === Before: Domain Pollution（外部形式によるドメイン汚染） ===
# 外部APIの独自フォーマットがドメインコード全体に散らばっている。

# --- WarehouseApi（外部APIのシミュレーション） ---
package WarehouseApi {
    use Moo;
    use Types::Standard qw(HashRef);

    has _stock_data  => (is => 'ro', isa => HashRef, default => sub { {} });
    has _reduce_log  => (is => 'rw', default => sub { [] });

    sub register_stock ($self, $product_id, $data) {
        $self->_stock_data->{$product_id} = $data;
    }

    # 外部APIの独自形式で返す
    sub get_stock ($self, $product_id) {
        return $self->_stock_data->{$product_id} // {
            qty_avlbl => 0,
            lst_upd   => '20260115',  # YYYYDDMM
            sts       => 0,
        };
    }

    sub reduce_stock ($self, $params) {
        push @{ $self->_reduce_log }, $params;
        return { result => 'ok' };
    }

    sub reduce_log ($self) { $self->_reduce_log }
}

# --- OrderService（アンチパターン: 外部形式がドメインに直接侵入） ---
package OrderService {
    use Moo;
    use Types::Standard qw(Object);

    has warehouse_api => (is => 'ro', isa => Object, required => 1);

    sub check_availability ($self, $product_id) {
        my $raw = $self->warehouse_api->get_stock($product_id);

        # 外部APIの形式を直接解釈
        my $quantity  = $raw->{qty_avlbl};
        my $raw_date  = $raw->{lst_upd};
        my $available = $raw->{sts} == 1;

        # YYYYDDMM → YYYY-MM-DD
        my ($y, $d, $m) = $raw_date =~ /^(\d{4})(\d{2})(\d{2})$/;
        my $updated_at = "$y-$m-$d";

        return {
            quantity   => $quantity,
            available  => $available,
            updated_at => $updated_at,
        };
    }

    sub place_order ($self, $product_id, $amount) {
        my $stock = $self->check_availability($product_id);
        die "Out of stock" unless $stock->{available};
        die "Insufficient stock" unless $stock->{quantity} >= $amount;

        return $self->warehouse_api->reduce_stock({
            prd_id  => $product_id,
            qty_rdc => $amount,
            sts     => 1,
        });
    }
}

1;

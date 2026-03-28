use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

# === After: Anti-Corruption Layer パターン ===
# 翻訳層で外部形式を遮断し、ドメインを汚染から守る。

# --- WarehouseApi（Before と同じ外部API） ---
package WarehouseApi {
    use Moo;
    use Types::Standard qw(HashRef);

    has _stock_data  => (is => 'ro', isa => HashRef, default => sub { {} });
    has _reduce_log  => (is => 'rw', default => sub { [] });

    sub register_stock ($self, $product_id, $data) {
        $self->_stock_data->{$product_id} = $data;
    }

    sub get_stock ($self, $product_id) {
        return $self->_stock_data->{$product_id} // {
            qty_avlbl => 0,
            lst_upd   => '20260115',
            sts       => 0,
        };
    }

    sub reduce_stock ($self, $params) {
        push @{ $self->_reduce_log }, $params;
        return { result => 'ok' };
    }

    sub reduce_log ($self) { $self->_reduce_log }
}

# --- Stock（ドメインオブジェクト: 自ドメインの言語） ---
package Stock {
    use Moo;
    use Types::Standard qw(Int Str Bool);

    has product_id => (is => 'ro', isa => Int, required => 1);
    has quantity   => (is => 'ro', isa => Int, required => 1);
    has available  => (is => 'ro', isa => Bool, required => 1);
    has updated_at => (is => 'ro', isa => Str, required => 1);
}

# --- WarehouseTranslator（Anti-Corruption Layer: 翻訳層） ---
package WarehouseTranslator {
    use Moo;
    use Types::Standard qw(Object);

    has api => (is => 'ro', isa => Object, required => 1);

    sub fetch_stock ($self, $product_id) {
        my $raw = $self->api->get_stock($product_id);
        return $self->_to_stock($product_id, $raw);
    }

    sub reduce_stock ($self, $product_id, $amount) {
        return $self->api->reduce_stock(
            $self->_to_external_reduce($product_id, $amount)
        );
    }

    sub _to_stock ($self, $product_id, $raw) {
        my ($y, $d, $m) = $raw->{lst_upd} =~ /^(\d{4})(\d{2})(\d{2})$/;
        return Stock->new(
            product_id => $product_id,
            quantity   => $raw->{qty_avlbl},
            available  => ($raw->{sts} == 1),
            updated_at => "$y-$m-$d",
        );
    }

    sub _to_external_reduce ($self, $product_id, $amount) {
        return {
            prd_id  => $product_id,
            qty_rdc => $amount,
            sts     => 1,
        };
    }
}

# --- OrderService（浄化済み: 自ドメインの言語だけで書かれている） ---
package OrderService {
    use Moo;
    use Types::Standard qw(Object);

    has warehouse => (is => 'ro', isa => Object, required => 1);

    sub check_availability ($self, $product_id) {
        return $self->warehouse->fetch_stock($product_id);
    }

    sub place_order ($self, $product_id, $amount) {
        my $stock = $self->check_availability($product_id);
        die "Out of stock" unless $stock->available;
        die "Insufficient stock" unless $stock->quantity >= $amount;
        return $self->warehouse->reduce_stock($product_id, $amount);
    }
}

1;

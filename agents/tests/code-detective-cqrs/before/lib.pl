use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use List::Util qw(sum0);

# === Before: Mixed Repository（読み書き混在リポジトリ） ===
# 受注登録（バリデーション付き書き込み）と
# 集計クエリ（顧客別合計・保留件数・サマリー）が同一クラスに同居。
# どちらかを変更するたびにもう片方のテストが壊れる。

package SalesOrderRepository {
    use Moo;
    use List::Util qw(sum0);

    has _orders => (is => 'ro', default => sub { [] });

    # === Command: 書き込み ===
    sub register ($self, %args) {
        die "顧客IDが必要です\n"       unless $args{customer_id};
        die "金額は正の整数が必要です\n" unless ($args{amount} // 0) > 0;
        die "商品リストが必要です\n"     unless $args{items} && @{$args{items}};

        my $order = {
            id          => sprintf('ORD-%04d', scalar(@{$self->_orders}) + 1),
            customer_id => $args{customer_id},
            amount      => $args{amount},
            items       => $args{items},
            status      => 'pending',
            created_at  => time(),
        };
        push @{$self->_orders}, $order;
        return $order;
    }

    sub complete_order ($self, $order_id) {
        my ($order) = grep { $_->{id} eq $order_id } @{$self->_orders};
        die "受注が見つかりません\n" unless $order;
        $order->{status} = 'completed';
        return $order;
    }

    # === Query: 読み取り ===
    sub total_by_customer ($self, $customer_id) {
        return sum0(map  { $_->{amount} }
                    grep { $_->{customer_id} eq $customer_id } @{$self->_orders});
    }

    sub pending_orders ($self) {
        return grep { $_->{status} eq 'pending' } @{$self->_orders};
    }

    sub summary ($self) {
        my @orders = @{$self->_orders};
        return {
            count   => scalar @orders,
            total   => sum0(map { $_->{amount} } @orders),
            pending => scalar(grep { $_->{status} eq 'pending' } @orders),
        };
    }
}

1;

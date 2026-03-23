use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use List::Util qw(sum0);

# === After: CQRS (Command Query Responsibility Segregation) ===
# Command側: 書き込み専用。バリデーションと業務ルールを守る責任のみ。
# Query側:   読み取り専用。集計・フィルタ・表示に最適化する責任のみ。
# どちらかを変更しても、もう片方に影響しない。

# --- Aggregate ---
package SalesOrder {
    use Moo;
    use Types::Standard qw(Str Int ArrayRef);

    has id          => (is => 'ro', isa => Str,      required => 1);
    has customer_id => (is => 'ro', isa => Str,      required => 1);
    has amount      => (is => 'ro', isa => Int,      required => 1);
    has items       => (is => 'ro', isa => ArrayRef, required => 1);
    has status      => (is => 'rw',                  default  => 'pending');
    has created_at  => (is => 'ro', isa => Int,      required => 1);
}

# --- Command Side: 書き込み専用 ---
package SalesOrderCommandRepository {
    use Moo;

    has _store => (is => 'ro', default => sub { [] });

    sub register ($self, %args) {
        die "顧客IDが必要です\n"       unless $args{customer_id};
        die "金額は正の整数が必要です\n" unless ($args{amount} // 0) > 0;
        die "商品リストが必要です\n"     unless $args{items} && @{$args{items}};

        my $order = SalesOrder->new(
            id          => sprintf('ORD-%04d', scalar(@{$self->_store}) + 1),
            customer_id => $args{customer_id},
            amount      => $args{amount},
            items       => $args{items},
            created_at  => time(),
        );
        push @{$self->_store}, $order;
        return $order;
    }

    sub complete ($self, $order_id) {
        my ($order) = grep { $_->id eq $order_id } @{$self->_store};
        die "受注が見つかりません\n" unless $order;
        $order->status('completed');
        return $order;
    }

    sub all ($self) { return @{$self->_store} }
}

# --- Query Side: 読み取り専用 ---
package SalesOrderQueryService {
    use Moo;
    use List::Util qw(sum0);

    has _command_repo => (is => 'ro', required => 1);

    sub total_by_customer ($self, $customer_id) {
        return sum0(map  { $_->amount }
                    grep { $_->customer_id eq $customer_id }
                    $self->_command_repo->all);
    }

    sub pending_orders ($self) {
        return grep { $_->status eq 'pending' } $self->_command_repo->all;
    }

    sub summary ($self) {
        my @orders = $self->_command_repo->all;
        return {
            count   => scalar @orders,
            total   => sum0(map { $_->amount } @orders),
            pending => scalar(grep { $_->status eq 'pending' } @orders),
        };
    }
}

1;

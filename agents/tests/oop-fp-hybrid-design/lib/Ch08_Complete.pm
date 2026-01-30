package Ch08_Complete;
use v5.36;

# 第8回: ハイブリッド設計の完成形
# ECサイト注文処理システムの完全実装

#=====================================================
# イミュータブルなデータ構造（DTO）
#=====================================================

package Ch08_Complete::OrderItem {
    use v5.36;
    use Moo;
    use Types::Standard qw(Str Int);

    has name     => (is => 'ro', isa => Str, required => 1);
    has price    => (is => 'ro', isa => Int->where(sub { $_ > 0 }), required => 1);
    has quantity => (is => 'ro', isa => Int->where(sub { $_ > 0 }), required => 1);

    sub total ($self) { $self->price * $self->quantity }

    sub with_quantity ($self, $qty) {
        return Ch08_Complete::OrderItem->new(
            name     => $self->name,
            price    => $self->price,
            quantity => $qty,
        );
    }
}

package Ch08_Complete::Order {
    use v5.36;
    use Moo;
    use Types::Standard qw(Str Int Num ArrayRef InstanceOf Maybe);

    has id             => (is => 'ro', isa => Maybe [Str]);
    has customer_name  => (is => 'ro', isa => Str, required => 1);
    has customer_email => (is => 'ro', isa => Str, required => 1);
    has items          => (is => 'ro', isa => ArrayRef [InstanceOf ['Ch08_Complete::OrderItem']], default => sub { [] });
    has discount_rate  => (is => 'ro', isa => Num->where(sub { $_ >= 0 && $_ <= 100 }), default => 0);
    has status         => (is => 'ro', isa => Str, default => 'pending');

    sub with_item ($self, $item) {
        return Ch08_Complete::Order->new(
            id             => $self->id,
            customer_name  => $self->customer_name,
            customer_email => $self->customer_email,
            items          => [@{$self->items}, $item],
            discount_rate  => $self->discount_rate,
            status         => $self->status,
        );
    }

    sub with_discount ($self, $rate) {
        return Ch08_Complete::Order->new(
            id             => $self->id,
            customer_name  => $self->customer_name,
            customer_email => $self->customer_email,
            items          => $self->items,
            discount_rate  => $rate,
            status         => $self->status,
        );
    }

    sub with_status ($self, $new_status) {
        return Ch08_Complete::Order->new(
            id             => $self->id,
            customer_name  => $self->customer_name,
            customer_email => $self->customer_email,
            items          => $self->items,
            discount_rate  => $self->discount_rate,
            status         => $new_status,
        );
    }

    sub with_id ($self, $new_id) {
        return Ch08_Complete::Order->new(
            id             => $new_id,
            customer_name  => $self->customer_name,
            customer_email => $self->customer_email,
            items          => $self->items,
            discount_rate  => $self->discount_rate,
            status         => $self->status,
        );
    }
}

#=====================================================
# Functional Core（純粋計算層）
#=====================================================

package Ch08_Complete::OrderCalculator {
    use v5.36;
    use List::Util qw(reduce);

    our $TAX_RATE                = 10;
    our $FREE_SHIPPING_THRESHOLD = 5000;
    our $SHIPPING_FEE            = 500;

    # 純粋関数: 小計計算
    sub calculate_subtotal ($order) {
        return reduce { $a + $b->total } 0, @{$order->items};
    }

    # 純粋関数: 割引額計算
    sub calculate_discount ($subtotal, $rate) {
        return int($subtotal * $rate / 100);
    }

    # 純粋関数: 税額計算
    sub calculate_tax ($amount) {
        return int($amount * $TAX_RATE / 100);
    }

    # 純粋関数: 送料計算
    sub calculate_shipping ($subtotal) {
        return $subtotal >= $FREE_SHIPPING_THRESHOLD ? 0 : $SHIPPING_FEE;
    }

    # 純粋関数: 注文合計の完全計算
    sub calculate_order_total ($order) {
        my $subtotal       = calculate_subtotal($order);
        my $discount       = calculate_discount($subtotal, $order->discount_rate);
        my $after_discount = $subtotal - $discount;
        my $tax            = calculate_tax($after_discount);
        my $shipping       = calculate_shipping($subtotal);

        return {
            subtotal       => $subtotal,
            discount       => $discount,
            after_discount => $after_discount,
            tax            => $tax,
            shipping       => $shipping,
            total          => $after_discount + $tax + $shipping,
        };
    }

    # 純粋関数: 注文検証
    sub validate_order ($order) {
        my @errors;

        push @errors, 'customer_name is required'
            unless $order->customer_name;

        push @errors, 'customer_email is required'
            unless $order->customer_email;

        push @errors, 'items must not be empty'
            unless @{$order->items};

        return {
            is_valid => @errors ? 0 : 1,
            errors   => \@errors,
        };
    }
}

#=====================================================
# Imperative Shell（副作用層）
#=====================================================

package Ch08_Complete::OrderRepository {
    use v5.36;
    use Moo;

    has _store   => (is => 'rw', default => sub { {} });
    has _next_id => (is => 'rw', default => 1);

    sub save ($self, $order) {
        my $id = 'ORD' . sprintf('%06d', $self->_next_id);
        $self->_next_id($self->_next_id + 1);

        my $saved_order = $order->with_id($id);
        $self->_store->{$id} = $saved_order;
        return $saved_order;
    }

    sub find ($self, $id) {
        return $self->_store->{$id};
    }

    sub update ($self, $order) {
        $self->_store->{$order->id} = $order;
        return $order;
    }
}

package Ch08_Complete::EmailService {
    use v5.36;
    use Moo;

    has _sent => (is => 'rw', default => sub { [] });

    sub send_confirmation ($self, $order, $calculation) {
        push @{$self->_sent},
            {
            to      => $order->customer_email,
            subject => "Order Confirmation: " . $order->id,
            body    => "Thank you! Total: ¥$calculation->{total}",
            };
        return 1;
    }

    sub get_sent ($self) { return $self->_sent; }
}

package Ch08_Complete::Logger {
    use v5.36;
    use Moo;

    has _logs => (is => 'rw', default => sub { [] });

    sub info     ($self, $msg) { push @{$self->_logs}, "[INFO] $msg";  say "[INFO] $msg"; }
    sub error    ($self, $msg) { push @{$self->_logs}, "[ERROR] $msg"; say "[ERROR] $msg"; }
    sub get_logs ($self)       { return $self->_logs; }
}

package Ch08_Complete::OrderService {
    use v5.36;
    use Moo;

    has repository => (is => 'ro', required => 1);
    has email      => (is => 'ro', required => 1);
    has logger     => (is => 'ro', required => 1);

    sub create_order ($self, $order) {

        # 1. 検証（Core）
        my $validation = Ch08_Complete::OrderCalculator::validate_order($order);
        unless ($validation->{is_valid}) {
            $self->logger->error("Validation failed: " . join(", ", @{$validation->{errors}}));
            return {success => 0, errors => $validation->{errors}};
        }

        # 2. 計算（Core）
        my $calculation = Ch08_Complete::OrderCalculator::calculate_order_total($order);

        # 3. 保存（Shell）
        my $saved_order = $self->repository->save($order->with_status('confirmed'));

        # 4. メール送信（Shell）
        $self->email->send_confirmation($saved_order, $calculation);

        # 5. ログ（Shell）
        $self->logger->info("Order " . $saved_order->id . " created: ¥$calculation->{total}");

        return {
            success     => 1,
            order       => $saved_order,
            calculation => $calculation,
        };
    }

    sub get_order ($self, $id) {
        return $self->repository->find($id);
    }
}

#=====================================================
# Demo: 完全な注文処理フロー
#=====================================================

package Ch08_Complete;

sub demonstrate_complete_system {
    say "=== ハイブリッド設計の完成形 ===\n";

    # Shell の構築（依存性注入）
    my $repo   = Ch08_Complete::OrderRepository->new;
    my $email  = Ch08_Complete::EmailService->new;
    my $logger = Ch08_Complete::Logger->new;

    my $service = Ch08_Complete::OrderService->new(
        repository => $repo,
        email      => $email,
        logger     => $logger,
    );

    # イミュータブルなデータ構造で注文を構築
    say "--- 注文の構築（イミュータブル） ---";
    my $order = Ch08_Complete::Order->new(
        customer_name  => 'Alice',
        customer_email => 'alice@example.com',
    );

    $order = $order->with_item(
        Ch08_Complete::OrderItem->new(
            name     => 'プログラミング入門書',
            price    => 3000,
            quantity => 1,
        )
    );

    $order = $order->with_item(
        Ch08_Complete::OrderItem->new(
            name     => 'ノート',
            price    => 500,
            quantity => 3,
        )
    );

    $order = $order->with_discount(10);    # 10%割引

    say "顧客: " . $order->customer_name;
    say "商品数: " . scalar(@{$order->items});
    say "割引率: " . $order->discount_rate . "%";

    # 注文処理
    say "\n--- 注文処理（FCISパターン） ---";
    my $result = $service->create_order($order);

    if ($result->{success}) {
        say "\n--- 処理結果 ---";
        say "注文ID: " . $result->{order}->{id};
        say "ステータス: " . $result->{order}->status;
        say "小計: ¥" . $result->{calculation}->{subtotal};
        say "割引: ¥" . $result->{calculation}->{discount};
        say "税額: ¥" . $result->{calculation}->{tax};
        say "送料: ¥" . $result->{calculation}->{shipping};
        say "合計: ¥" . $result->{calculation}->{total};

        say "\n--- 送信されたメール ---";
        for my $mail (@{$email->get_sent}) {
            say "To: $mail->{to}";
            say "Subject: $mail->{subject}";
        }
    }

    return $result;
}

1;

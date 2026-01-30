package Ch05_FCIS;
use v5.36;

# 第5回: Functional Core, Imperative Shell (FCIS) パターン
# ビジネスロジックとI/Oの分離

#=====================================================
# Functional Core（純粋計算層）
#=====================================================

package Ch05_FCIS::OrderCalculator {
    use v5.36;

    # 純粋関数: 割引計算
    sub calculate_discount ($subtotal, $discount_rate) {
        return $subtotal * ($discount_rate / 100);
    }

    # 純粋関数: 税金計算
    sub calculate_tax ($amount, $tax_rate) {
        return int($amount * ($tax_rate / 100));
    }

    # 純粋関数: 送料計算
    sub calculate_shipping ($subtotal, $threshold, $shipping_fee) {
        return $subtotal >= $threshold ? 0 : $shipping_fee;
    }

    # 純粋関数: 合計計算
    sub calculate_total ($params) {
        my $subtotal       = $params->{subtotal};
        my $discount       = calculate_discount($subtotal, $params->{discount_rate} // 0);
        my $after_discount = $subtotal - $discount;
        my $tax            = calculate_tax($after_discount, $params->{tax_rate} // 10);
        my $shipping       = calculate_shipping($subtotal, $params->{free_shipping_threshold} // 5000, $params->{shipping_fee} // 500);

        return {
            subtotal       => $subtotal,
            discount       => $discount,
            after_discount => $after_discount,
            tax            => $tax,
            shipping       => $shipping,
            total          => $after_discount + $tax + $shipping,
        };
    }

    # 純粋関数: 注文の検証
    sub validate_order ($order) {
        my @errors;

        push @errors, 'customer_name is required'
            unless $order->{customer_name};

        push @errors, 'items must not be empty'
            unless $order->{items} && @{$order->{items}};

        for my $item (@{$order->{items} // []}) {
            push @errors, "item name is required"
                unless $item->{name};
            push @errors, "item price must be positive"
                unless ($item->{price} // 0) > 0;
            push @errors, "item quantity must be positive"
                unless ($item->{quantity} // 0) > 0;
        }

        return {
            is_valid => @errors ? 0 : 1,
            errors   => \@errors,
        };
    }
}

#=====================================================
# Imperative Shell（副作用層）
#=====================================================

package Ch05_FCIS::OrderService {
    use v5.36;
    use Moo;

    has db     => (is => 'ro', required => 1);
    has mailer => (is => 'ro', required => 1);
    has logger => (is => 'ro', required => 1);

    sub process_order ($self, $order_data) {

        # 1. 純粋関数で検証（Core）
        my $validation = Ch05_FCIS::OrderCalculator::validate_order($order_data);
        unless ($validation->{is_valid}) {
            $self->logger->error("Validation failed: " . join(", ", @{$validation->{errors}}));
            return {success => 0, errors => $validation->{errors}};
        }

        # 2. 小計を計算（純粋）
        my $subtotal = 0;
        for my $item (@{$order_data->{items}}) {
            $subtotal += $item->{price} * $item->{quantity};
        }

        # 3. 純粋関数で合計計算（Core）
        my $calculation = Ch05_FCIS::OrderCalculator::calculate_total(
            {
                subtotal                => $subtotal,
                discount_rate           => $order_data->{discount_rate} // 0,
                tax_rate                => 10,
                free_shipping_threshold => 5000,
                shipping_fee            => 500,
            }
        );

        # 4. DB保存（Shell - 副作用）
        my $order_id = $self->db->save_order({%$order_data, %$calculation,});

        # 5. メール送信（Shell - 副作用）
        $self->mailer->send_confirmation(
            $order_data->{customer_email},
            {
                order_id => $order_id,
                total    => $calculation->{total},
            }
        );

        # 6. ログ出力（Shell - 副作用）
        $self->logger->info("Order $order_id processed: ¥$calculation->{total}");

        return {
            success  => 1,
            order_id => $order_id,
            total    => $calculation->{total},
        };
    }
}

#=====================================================
# Mock implementations for testing
#=====================================================

package Ch05_FCIS::MockDB {
    use v5.36;
    use Moo;

    has orders  => (is => 'rw', default => sub { [] });
    has next_id => (is => 'rw', default => 1);

    sub save_order ($self, $order) {
        my $id = 'ORD' . sprintf('%05d', $self->next_id);
        $self->next_id($self->next_id + 1);
        push @{$self->orders}, {id => $id, %$order};
        return $id;
    }
}

package Ch05_FCIS::MockMailer {
    use v5.36;
    use Moo;

    has sent => (is => 'rw', default => sub { [] });

    sub send_confirmation ($self, $email, $data) {
        push @{$self->sent}, {to => $email, %$data};
        return 1;
    }
}

package Ch05_FCIS::MockLogger {
    use v5.36;
    use Moo;

    has logs => (is => 'rw', default => sub { [] });

    sub info  ($self, $msg) { push @{$self->logs}, {level => 'info',  message => $msg}; }
    sub error ($self, $msg) { push @{$self->logs}, {level => 'error', message => $msg}; }
}

#=====================================================
# Demo
#=====================================================

package Ch05_FCIS;

sub demonstrate_fcis {
    say "=== FCIS パターンのデモ ===\n";

    # Shell の構築（依存性注入）
    my $db     = Ch05_FCIS::MockDB->new;
    my $mailer = Ch05_FCIS::MockMailer->new;
    my $logger = Ch05_FCIS::MockLogger->new;

    my $service = Ch05_FCIS::OrderService->new(
        db     => $db,
        mailer => $mailer,
        logger => $logger,
    );

    # 注文処理
    my $result = $service->process_order(
        {
            customer_name  => 'Alice',
            customer_email => 'alice@example.com',
            items          => [{name => 'Book', price => 1000, quantity => 2}, {name => 'Pen', price => 200, quantity => 5},],
            discount_rate  => 10,
        }
    );

    say "処理結果:";
    say "  成功: " . ($result->{success} ? 'Yes' : 'No');
    say "  注文ID: " . $result->{order_id} if $result->{order_id};
    say "  合計: ¥" . $result->{total}     if $result->{total};

    say "\n送信されたメール:";
    for my $mail (@{$mailer->sent}) {
        say "  To: $mail->{to}, Order: $mail->{order_id}, Total: ¥$mail->{total}";
    }

    return $result;
}

1;

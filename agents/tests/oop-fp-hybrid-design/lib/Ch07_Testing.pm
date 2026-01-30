package Ch07_Testing;
use v5.36;

# 第7回: テストが書きやすい設計 - FCISパターンの真価
# Functional Core は純粋関数なのでモック不要で高速テスト
# Imperative Shell は薄いので統合テストも簡単

#=====================================================
# Functional Core（テスト対象）
#=====================================================

package Ch07_Testing::OrderCalculator {
    use v5.36;
    use Exporter 'import';
    our @EXPORT_OK = qw(
        calculate_subtotal
        calculate_discount
        calculate_tax
        calculate_shipping
        calculate_total
        validate_order
    );

    # 純粋関数: 小計計算
    sub calculate_subtotal ($items) {
        my $total = 0;
        $total += $_->{price} * $_->{quantity} for @$items;
        return $total;
    }

    # 純粋関数: 割引計算
    sub calculate_discount ($subtotal, $rate) {
        return $subtotal * ($rate / 100);
    }

    # 純粋関数: 税金計算
    sub calculate_tax ($amount, $rate) {
        return int($amount * ($rate / 100));
    }

    # 純粋関数: 送料計算
    sub calculate_shipping ($subtotal, $threshold, $fee) {
        return $subtotal >= $threshold ? 0 : $fee;
    }

    # 純粋関数: 合計計算（他の純粋関数を組み合わせ）
    sub calculate_total ($params) {
        my $subtotal       = calculate_subtotal($params->{items});
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

    # 純粋関数: 注文検証
    sub validate_order ($order) {
        my @errors;

        push @errors, 'customer_name is required'
            unless $order->{customer_name};

        push @errors, 'items must not be empty'
            unless $order->{items} && @{$order->{items}};

        for my $item (@{$order->{items} // []}) {
            push @errors, "item '$item->{name}': price must be positive"
                unless ($item->{price} // 0) > 0;
            push @errors, "item '$item->{name}': quantity must be positive"
                unless ($item->{quantity} // 0) > 0;
        }

        return {
            is_valid => @errors ? 0 : 1,
            errors   => \@errors,
        };
    }
}

#=====================================================
# テスト例: 単体テスト（Core）
#=====================================================

package Ch07_Testing::UnitTests {
    use v5.36;

    sub run_tests {
        say "=== 単体テスト（Core） ===\n";
        my $passed = 0;
        my $failed = 0;

        # Test 1: calculate_subtotal
        {
            my @items  = ({price => 1000, quantity => 2}, {price => 500, quantity => 3},);
            my $result = Ch07_Testing::OrderCalculator::calculate_subtotal(\@items);
            if ($result == 3500) {
                say "✓ calculate_subtotal: 正常な合計計算";
                $passed++;
            }
            else {
                say "✗ calculate_subtotal: 期待値 3500, 実際 $result";
                $failed++;
            }
        }

        # Test 2: calculate_discount
        {
            my $result = Ch07_Testing::OrderCalculator::calculate_discount(10000, 10);
            if ($result == 1000) {
                say "✓ calculate_discount: 10%割引";
                $passed++;
            }
            else {
                say "✗ calculate_discount: 期待値 1000, 実際 $result";
                $failed++;
            }
        }

        # Test 3: calculate_tax
        {
            my $result = Ch07_Testing::OrderCalculator::calculate_tax(1000, 10);
            if ($result == 100) {
                say "✓ calculate_tax: 10%税金";
                $passed++;
            }
            else {
                say "✗ calculate_tax: 期待値 100, 実際 $result";
                $failed++;
            }
        }

        # Test 4: calculate_shipping (free)
        {
            my $result = Ch07_Testing::OrderCalculator::calculate_shipping(5000, 5000, 500);
            if ($result == 0) {
                say "✓ calculate_shipping: 送料無料ライン以上";
                $passed++;
            }
            else {
                say "✗ calculate_shipping: 期待値 0, 実際 $result";
                $failed++;
            }
        }

        # Test 5: calculate_shipping (charged)
        {
            my $result = Ch07_Testing::OrderCalculator::calculate_shipping(4999, 5000, 500);
            if ($result == 500) {
                say "✓ calculate_shipping: 送料無料ライン未満";
                $passed++;
            }
            else {
                say "✗ calculate_shipping: 期待値 500, 実際 $result";
                $failed++;
            }
        }

        # Test 6: validate_order (valid)
        {
            my $order = {
                customer_name => 'Alice',
                items         => [{name => 'Book', price => 1000, quantity => 1}],
            };
            my $result = Ch07_Testing::OrderCalculator::validate_order($order);
            if ($result->{is_valid}) {
                say "✓ validate_order: 有効な注文";
                $passed++;
            }
            else {
                say "✗ validate_order: 有効な注文が無効と判定";
                $failed++;
            }
        }

        # Test 7: validate_order (invalid - no customer)
        {
            my $order  = {items => [{name => 'Book', price => 1000, quantity => 1}],};
            my $result = Ch07_Testing::OrderCalculator::validate_order($order);
            if (!$result->{is_valid} && grep {/customer_name/} @{$result->{errors}}) {
                say "✓ validate_order: 顧客名なしは無効";
                $passed++;
            }
            else {
                say "✗ validate_order: 顧客名なしが検出されず";
                $failed++;
            }
        }

        say "\n結果: $passed passed, $failed failed";
        return {passed => $passed, failed => $failed};
    }
}

#=====================================================
# Demo
#=====================================================

package Ch07_Testing;

sub demonstrate_testing {

    # 単体テスト実行
    my $results = Ch07_Testing::UnitTests::run_tests();

    say "\n=== テスト戦略の解説 ===";
    say "• Functional Core は純粋関数なので:";
    say "  - モック不要（外部依存なし）";
    say "  - 高速実行（I/Oなし）";
    say "  - 決定的（同じ入力 → 同じ出力）";
    say "";
    say "• Imperative Shell は薄いレイヤーなので:";
    say "  - 統合テストは最小限でOK";
    say "  - モックを使う場合も単純";
    say "  - 「配線」のテストに集中";

    return $results;
}

1;

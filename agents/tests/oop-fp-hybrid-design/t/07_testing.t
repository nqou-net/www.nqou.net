#!/usr/bin/env perl
use v5.36;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

# 第7回: テストが書きやすい設計

subtest '第7回 - テストが書きやすい設計' => sub {
    use_ok('Ch07_Testing');

    subtest 'OrderCalculator の純粋関数はテストが簡単' => sub {

        # calculate_subtotal
        my $subtotal = Ch07_Testing::OrderCalculator::calculate_subtotal([{price => 1000, quantity => 2}, {price => 500, quantity => 3},]);
        is($subtotal, 3500, 'calculate_subtotal');

        # calculate_discount
        is(Ch07_Testing::OrderCalculator::calculate_discount(10000, 10), 1000, 'calculate_discount');

        # calculate_tax
        is(Ch07_Testing::OrderCalculator::calculate_tax(1000, 10), 100, 'calculate_tax');

        # calculate_shipping
        is(Ch07_Testing::OrderCalculator::calculate_shipping(5000, 5000, 500), 0,   'shipping free');
        is(Ch07_Testing::OrderCalculator::calculate_shipping(4999, 5000, 500), 500, 'shipping charged');
    };

    subtest 'calculate_total は複合計算' => sub {
        my $result = Ch07_Testing::OrderCalculator::calculate_total(
            {
                items                   => [{price => 3000, quantity => 1}, {price => 500, quantity => 3},],
                discount_rate           => 10,
                tax_rate                => 10,
                free_shipping_threshold => 5000,
                shipping_fee            => 500,
            }
        );

        is($result->{subtotal},       4500, '小計');
        is($result->{discount},       450,  '割引');
        is($result->{after_discount}, 4050, '割引後');
        is($result->{tax},            405,  '税金');
        is($result->{shipping},       500,  '送料（有料）');
        is($result->{total},          4955, '合計');
    };

    subtest 'validate_order は正常ケース' => sub {
        my $result = Ch07_Testing::OrderCalculator::validate_order(
            {
                customer_name => 'Alice',
                items         => [{name => 'Book', price => 1000, quantity => 1}],
            }
        );

        ok($result->{is_valid}, '有効な注文');
        is(scalar(@{$result->{errors}}), 0, 'エラーなし');
    };

    subtest 'validate_order は異常ケース' => sub {
        my $result = Ch07_Testing::OrderCalculator::validate_order(
            {
                items => [],
            }
        );

        ok(!$result->{is_valid}, '無効な注文');
        ok(grep(/customer_name/, @{$result->{errors}}), 'customer_nameエラー');
        ok(grep(/items/,         @{$result->{errors}}), 'itemsエラー');
    };

    subtest '価格・数量の検証' => sub {
        my $result = Ch07_Testing::OrderCalculator::validate_order(
            {
                customer_name => 'Alice',
                items         => [{name => 'Book', price => 0, quantity => 1},],
            }
        );

        ok(!$result->{is_valid},                '価格0は無効');
        ok(grep(/price/, @{$result->{errors}}), 'priceエラー');
    };

    subtest 'UnitTests::run_tests でテストスイート実行' => sub {

        # 出力を抑制
        my $old_stdout = select;
        open my $fh, '>', \my $output;
        select $fh;

        my $results = Ch07_Testing::UnitTests::run_tests();

        select $old_stdout;
        close $fh;

        ok($results->{passed} > 0, 'いくつかのテストがpass');
        is($results->{failed}, 0, '失敗したテストなし');
    };
};

done_testing;

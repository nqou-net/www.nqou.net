#!/usr/bin/env perl
use v5.36;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

# 第3回: 純粋関数と副作用の分離

subtest '第3回 - 純粋関数と副作用の分離' => sub {
    use_ok('Ch03_PureFunction');
    Ch03_PureFunction->import(
        qw(
            calculate_subtotal_pure
            calculate_discount_pure
            calculate_total_pure
        )
    );

    subtest 'calculate_subtotal_pure は純粋関数' => sub {
        my @items = ({name => 'Book', price => 1000, quantity => 2}, {name => 'Pen', price => 200, quantity => 5},);

        # 同じ入力に対して常に同じ出力
        my $result1 = calculate_subtotal_pure(\@items);
        my $result2 = calculate_subtotal_pure(\@items);

        is($result1, 3000,     '小計が正しく計算される');
        is($result1, $result2, '同じ入力 → 同じ出力（純粋関数の性質）');
    };

    subtest 'calculate_discount_pure は純粋関数' => sub {
        is(calculate_discount_pure(10000, 10), 1000, '10%割引');
        is(calculate_discount_pure(10000, 20), 2000, '20%割引');
        is(calculate_discount_pure(0,     10), 0,    '0円の10%は0円');
    };

    subtest 'calculate_total_pure は純粋関数' => sub {
        is(calculate_total_pure(10000, 1000), 9000, '10000 - 1000 = 9000');
        is(calculate_total_pure(5000,  500),  4500, '5000 - 500 = 4500');
    };

    subtest '純粋関数の組み合わせ' => sub {
        my @items = ({name => 'A', price => 2000, quantity => 1}, {name => 'B', price => 1000, quantity => 3},);

        my $subtotal = calculate_subtotal_pure(\@items);
        is($subtotal, 5000, '小計: 2000 + 3000 = 5000');

        my $discount = calculate_discount_pure($subtotal, 10);
        is($discount, 500, '割引: 5000 * 10% = 500');

        my $total = calculate_total_pure($subtotal, $discount);
        is($total, 4500, '合計: 5000 - 500 = 4500');
    };
};

done_testing;

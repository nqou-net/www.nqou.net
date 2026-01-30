#!/usr/bin/env perl
use v5.36;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

# 第1回: 可変状態の問題
# このテストでは、Mutableなオブジェクトの問題点を示す

subtest '第1回 - 可変状態の問題を示す' => sub {
    use_ok('Ch01_Order_Mutable');

    subtest 'Mutableなオブジェクトが作成できる' => sub {
        my $order = Ch01_Order_Mutable->new(customer_name => 'Test');
        ok($order, 'オブジェクト作成成功');
        is($order->customer_name, 'Test', '顧客名が設定される');
    };

    subtest '状態が直接変更できてしまう（問題の根源）' => sub {
        my $order = Ch01_Order_Mutable->new(customer_name => 'Alice');

        # 初期状態
        is($order->discount_rate, 0, '初期割引率は0');

        # 状態を直接変更
        $order->apply_discount(10);
        is($order->discount_rate, 10, '割引率を10に変更');

        # 別の場所で上書き（問題！）
        $order->apply_discount(20);
        is($order->discount_rate, 20, '割引率が20に上書きされた（10%が消えた）');

        # 本来は10+20=30%を期待していた場合、これはバグ
        note('この動作は意図しない場合があり、バグの原因になる');
    };

    subtest 'add_item で商品を追加できる' => sub {
        my $order = Ch01_Order_Mutable->new(customer_name => 'Bob');
        $order->add_item({name => 'Book', price => 1000, quantity => 2});

        is(scalar(@{$order->items}), 1,    '商品が1件追加された');
        is($order->total,            2000, '合計が正しく計算される');
    };
};

done_testing;

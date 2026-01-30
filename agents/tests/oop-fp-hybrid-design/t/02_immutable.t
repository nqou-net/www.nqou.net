#!/usr/bin/env perl
use v5.36;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

# 第2回: イミュータブルオブジェクト

subtest '第2回 - イミュータブルオブジェクト' => sub {
    use_ok('Ch02_Order_Immutable');

    subtest 'イミュータブルなオブジェクトが作成できる' => sub {
        my $order = Ch02_Order_Immutable->new(customer_name => 'Alice');
        ok($order, 'オブジェクト作成成功');
        is($order->customer_name, 'Alice', '顧客名が設定される');
        is($order->discount_rate, 0,       '初期割引率は0');
    };

    subtest 'with_item で新しいオブジェクトが返される' => sub {
        my $original  = Ch02_Order_Immutable->new(customer_name => 'Alice');
        my $with_item = $original->with_item({name => 'Book', price => 1000, quantity => 2});

        isnt($original, $with_item, '新しいオブジェクトが返される');
        is(scalar(@{$original->items}),  0, '元のオブジェクトは変更されない');
        is(scalar(@{$with_item->items}), 1, '新しいオブジェクトに商品が追加される');
    };

    subtest 'with_discount で新しいオブジェクトが返される' => sub {
        my $original      = Ch02_Order_Immutable->new(customer_name => 'Alice');
        my $with_discount = $original->with_discount(10);

        isnt($original, $with_discount, '新しいオブジェクトが返される');
        is($original->discount_rate,      0,  '元のオブジェクトは変更されない');
        is($with_discount->discount_rate, 10, '新しいオブジェクトに割引が適用される');
    };

    subtest 'with_additional_discount で割引が合算される' => sub {
        my $order = Ch02_Order_Immutable->new(customer_name => 'Alice',)->with_item({name => 'Book', price => 1000, quantity => 2});

        my $with_coupon = $order->with_additional_discount(10);          # クーポン10%
        my $with_both   = $with_coupon->with_additional_discount(20);    # 会員20%

        is($with_both->discount_rate, 30,   '割引が合算される（10% + 20% = 30%）');
        is($with_both->total,         1400, '合計金額が正しい（2000 * 0.7 = 1400）');
    };

    subtest 'チェーンで複数の変更を適用できる' => sub {
        my $order
            = Ch02_Order_Immutable->new(customer_name => 'Alice')
            ->with_item({name => 'Book', price => 1000, quantity => 1})
            ->with_item({name => 'Pen',  price => 200,  quantity => 5})
            ->with_discount(10);

        is(scalar(@{$order->items}), 2,    '2商品追加');
        is($order->discount_rate,    10,   '10%割引');
        is($order->total,            1800, '合計: (1000 + 1000) * 0.9 = 1800');
    };
};

done_testing;

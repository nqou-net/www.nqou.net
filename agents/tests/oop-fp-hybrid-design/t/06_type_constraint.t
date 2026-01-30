#!/usr/bin/env perl
use v5.36;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

# 第6回: 型制約

subtest '第6回 - 型制約（Types::Standard）' => sub {
    use_ok('Ch06_TypeConstraint');

    subtest 'OrderItem は型制約を持つ' => sub {
        my $item = Ch06_TypeConstraint::OrderItem->new(
            name     => 'Book',
            price    => 1000,
            quantity => 2,
        );

        ok($item, 'オブジェクト作成成功');
        is($item->name,     'Book', 'name が設定される');
        is($item->price,    1000,   'price が設定される');
        is($item->quantity, 2,      'quantity が設定される');
        is($item->total,    2000,   'total が計算される');
    };

    subtest '負の価格は拒否される' => sub {
        eval { Ch06_TypeConstraint::OrderItem->new(name => 'Invalid', price => -100, quantity => 1,); };
        ok($@, '負の価格でエラーが発生');
        like($@, qr/price/, 'price に関するエラー');
    };

    subtest '負の数量は拒否される' => sub {
        eval { Ch06_TypeConstraint::OrderItem->new(name => 'Invalid', price => 100, quantity => 0,); };
        ok($@, '0の数量でエラーが発生');
    };

    subtest 'Order は型制約付きイミュータブル' => sub {
        my $item = Ch06_TypeConstraint::OrderItem->new(
            name     => 'Book',
            price    => 1000,
            quantity => 2,
        );

        my $order = Ch06_TypeConstraint::Order->new(
            customer_name  => 'Alice',
            customer_email => 'alice@example.com',
            items          => [$item],
            discount_rate  => 10,
        );

        ok($order, 'Order 作成成功');
        is($order->subtotal,        2000, '小計');
        is($order->discount_amount, 200,  '割引額');
        is($order->total,           1800, '合計');
    };

    subtest '空の顧客名は拒否される' => sub {
        eval { Ch06_TypeConstraint::Order->new(customer_name => '', customer_email => 'test@example.com',); };
        ok($@, '空の顧客名でエラーが発生');
    };

    subtest '不正なメール形式は拒否される' => sub {
        eval { Ch06_TypeConstraint::Order->new(customer_name => 'Alice', customer_email => 'invalid-email',); };
        ok($@, '不正なメール形式でエラーが発生');
    };

    subtest '割引率は0-100の範囲' => sub {
        eval { Ch06_TypeConstraint::Order->new(customer_name => 'Alice', customer_email => 'alice@example.com', discount_rate => 150,); };
        ok($@, '150%割引でエラーが発生');
    };

    subtest 'with_item で新しいOrderが返される' => sub {
        my $order = Ch06_TypeConstraint::Order->new(
            customer_name  => 'Alice',
            customer_email => 'alice@example.com',
        );

        my $new_item = Ch06_TypeConstraint::OrderItem->new(
            name     => 'Pen',
            price    => 200,
            quantity => 5,
        );

        my $new_order = $order->with_item($new_item);

        isnt($order, $new_order, '新しいオブジェクト');
        is(scalar(@{$order->items}),     0, '元のOrderは不変');
        is(scalar(@{$new_order->items}), 1, '新しいOrderに商品追加');
    };
};

done_testing;

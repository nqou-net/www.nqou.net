#!/usr/bin/env perl
use v5.36;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

# 第8回: ハイブリッド設計の完成形

subtest '第8回 - ハイブリッド設計の完成形' => sub {
    use_ok('Ch08_Complete');

    subtest 'OrderItem はイミュータブル' => sub {
        my $item = Ch08_Complete::OrderItem->new(
            name     => 'Book',
            price    => 1000,
            quantity => 2,
        );

        ok($item, 'OrderItem 作成成功');
        is($item->total, 2000, 'total 計算');

        my $new_item = $item->with_quantity(5);
        isnt($item, $new_item, '新しいオブジェクト');
        is($item->quantity,     2, '元は不変');
        is($new_item->quantity, 5, '新しい数量');
    };

    subtest 'Order はイミュータブルで with_* パターン' => sub {
        my $order = Ch08_Complete::Order->new(
            customer_name  => 'Alice',
            customer_email => 'alice@example.com',
        );

        my $item = Ch08_Complete::OrderItem->new(
            name     => 'Book',
            price    => 1000,
            quantity => 2,
        );

        my $with_item = $order->with_item($item);
        isnt($order, $with_item, '新しいオブジェクト');
        is(scalar(@{$order->items}),     0, '元は不変');
        is(scalar(@{$with_item->items}), 1, '新しいOrderに商品');

        my $with_discount = $with_item->with_discount(10);
        is($with_item->discount_rate,     0,  '元は不変');
        is($with_discount->discount_rate, 10, '新しい割引');
    };

    subtest 'OrderCalculator（Core）は純粋関数' => sub {
        my $order = Ch08_Complete::Order->new(
            customer_name  => 'Alice',
            customer_email => 'alice@example.com',
        )->with_item(Ch08_Complete::OrderItem->new(name => 'A', price => 3000, quantity => 2));

        my $subtotal = Ch08_Complete::OrderCalculator::calculate_subtotal($order);
        is($subtotal, 6000, '小計計算');

        my $result = Ch08_Complete::OrderCalculator::calculate_order_total($order);
        is($result->{subtotal}, 6000, '小計');
        is($result->{shipping}, 0,    '送料無料');
        ok($result->{total} > 0, '合計が計算される');
    };

    subtest 'OrderService（Shell）は全体を統合' => sub {
        my $repo   = Ch08_Complete::OrderRepository->new;
        my $email  = Ch08_Complete::EmailService->new;
        my $logger = Ch08_Complete::Logger->new;

        my $service = Ch08_Complete::OrderService->new(
            repository => $repo,
            email      => $email,
            logger     => $logger,
        );

        my $order = Ch08_Complete::Order->new(
            customer_name  => 'Alice',
            customer_email => 'alice@example.com',
        )->with_item(Ch08_Complete::OrderItem->new(name => 'Book', price => 1000, quantity => 2))->with_discount(10);

        my $result = $service->create_order($order);

        ok($result->{success}, '処理成功');
        like($result->{order}->id, qr/^ORD/, '注文IDが生成');
        is($result->{order}->status, 'confirmed', 'ステータスが確認済み');

        # 副作用の確認
        is(scalar(@{$email->get_sent}), 1, 'メール送信');
        ok(scalar(@{$logger->get_logs}) > 0, 'ログ記録');
    };

    subtest '検証エラーは早期に検出' => sub {
        my $repo   = Ch08_Complete::OrderRepository->new;
        my $email  = Ch08_Complete::EmailService->new;
        my $logger = Ch08_Complete::Logger->new;

        my $service = Ch08_Complete::OrderService->new(
            repository => $repo,
            email      => $email,
            logger     => $logger,
        );

        my $invalid_order = Ch08_Complete::Order->new(
            customer_name  => '',                   # 空
            customer_email => 'test@example.com',
        );

        my $result = $service->create_order($invalid_order);

        ok(!$result->{success},                         '処理失敗');
        ok(grep(/customer_name/, @{$result->{errors}}), 'customer_nameエラー');

        # 副作用は発生しない
        is(scalar(@{$email->get_sent}), 0, 'メール未送信');
    };

    subtest '完全なフローのデモ' => sub {

        # 出力を抑制
        my $old_stdout = select;
        open my $fh, '>', \my $output;
        select $fh;

        my $result = Ch08_Complete::demonstrate_complete_system();

        select $old_stdout;
        close $fh;

        ok($result->{success},                  'デモ成功');
        ok($result->{calculation}->{total} > 0, '合計が計算される');
    };
};

done_testing;

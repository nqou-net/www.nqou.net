#!/usr/bin/env perl
use v5.36;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

# 第5回: FCIS パターン

subtest '第5回 - Functional Core, Imperative Shell' => sub {
    use_ok('Ch05_FCIS');

    subtest 'OrderCalculator（Core）は純粋関数' => sub {

        # calculate_discount
        is(Ch05_FCIS::OrderCalculator::calculate_discount(10000, 10), 1000, '割引計算が正しい');

        # calculate_tax
        is(Ch05_FCIS::OrderCalculator::calculate_tax(1000, 10), 100, '税金計算が正しい');

        # calculate_shipping（無料）
        is(Ch05_FCIS::OrderCalculator::calculate_shipping(5000, 5000, 500), 0, '送料無料ライン以上は0');

        # calculate_shipping（有料）
        is(Ch05_FCIS::OrderCalculator::calculate_shipping(4999, 5000, 500), 500, '送料無料ライン未満は有料');
    };

    subtest 'validate_order は検証ルールを適用' => sub {
        my $valid_order = {
            customer_name => 'Alice',
            items         => [{name => 'Book', price => 1000, quantity => 1}],
        };
        my $result = Ch05_FCIS::OrderCalculator::validate_order($valid_order);
        ok($result->{is_valid}, '有効な注文');

        my $invalid_order = {items => []};
        $result = Ch05_FCIS::OrderCalculator::validate_order($invalid_order);
        ok(!$result->{is_valid}, '無効な注文');
        ok(grep(/customer_name/, @{$result->{errors}}), 'customer_nameエラー');
        ok(grep(/items/,         @{$result->{errors}}), 'itemsエラー');
    };

    subtest 'calculate_total は完全な計算を行う' => sub {
        my $result = Ch05_FCIS::OrderCalculator::calculate_total(
            {
                subtotal                => 10000,
                discount_rate           => 10,
                tax_rate                => 10,
                free_shipping_threshold => 5000,
                shipping_fee            => 500,
            }
        );

        is($result->{subtotal},       10000, '小計');
        is($result->{discount},       1000,  '割引');
        is($result->{after_discount}, 9000,  '割引後');
        is($result->{tax},            900,   '税金');
        is($result->{shipping},       0,     '送料（無料）');
        is($result->{total},          9900,  '合計');
    };

    subtest 'OrderService（Shell）は副作用を含む' => sub {
        my $db     = Ch05_FCIS::MockDB->new;
        my $mailer = Ch05_FCIS::MockMailer->new;
        my $logger = Ch05_FCIS::MockLogger->new;

        my $service = Ch05_FCIS::OrderService->new(
            db     => $db,
            mailer => $mailer,
            logger => $logger,
        );

        my $result = $service->process_order(
            {
                customer_name  => 'Alice',
                customer_email => 'alice@example.com',
                items          => [{name => 'Book', price => 1000, quantity => 2}],
                discount_rate  => 0,
            }
        );

        ok($result->{success}, '処理成功');
        like($result->{order_id}, qr/^ORD/, '注文IDが生成される');
        ok($result->{total} > 0, '合計が計算される');

        # 副作用の確認
        is(scalar(@{$db->orders}),   1, 'DBに保存された');
        is(scalar(@{$mailer->sent}), 1, 'メールが送信された');
        ok(scalar(@{$logger->logs}) > 0, 'ログが記録された');
    };
};

done_testing;

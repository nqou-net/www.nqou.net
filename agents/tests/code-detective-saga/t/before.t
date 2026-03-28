use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use Test::More;

do './agents/tests/code-detective-saga/before/lib.pl' or die $@ || $!;

subtest 'Before: 正常系 — 全ステップ成功で注文完了' => sub {
    my $payment   = PaymentService->new;
    my $inventory = InventoryService->new;
    my $shipping  = ShippingService->new;
    my $processor = OrderProcessor->new(
        payment_service   => $payment,
        inventory_service => $inventory,
        shipping_service  => $shipping,
    );

    my $result = $processor->process_order({
        amount   => 5000,
        item_id  => 'ITEM-001',
        quantity => 2,
        address  => 'Tokyo, Japan',
    });

    is($result->{payment}{amount}, 5000, '決済額が正しい');
    is($result->{reservation}{item_id}, 'ITEM-001', '在庫引当の商品IDが正しい');
    is($result->{shipment}{address}, 'Tokyo, Japan', '配送先が正しい');
    is($payment->charge_count, 1, '決済が1回実行された');
    is($inventory->reservation_count, 1, '在庫引当が1回実行された');
    is($shipping->shipment_count, 1, '配送手配が1回実行された');
};

subtest 'Before: 問題点 — 在庫引当失敗時に決済が残る' => sub {
    my $payment   = PaymentService->new;
    my $inventory = InventoryService->new(should_fail => 1);
    my $shipping  = ShippingService->new;
    my $processor = OrderProcessor->new(
        payment_service   => $payment,
        inventory_service => $inventory,
        shipping_service  => $shipping,
    );

    eval {
        $processor->process_order({
            amount   => 3000,
            item_id  => 'ITEM-002',
            quantity => 1,
            address  => 'Osaka, Japan',
        });
    };
    like($@, qr/Out of stock/, '在庫引当でエラー');

    # 問題: 決済だけ成功して残っている
    is($payment->charge_count, 1, '決済は実行済み（返金されない！）');
    is($inventory->reservation_count, 0, '在庫引当は失敗');
    is($shipping->shipment_count, 0, '配送手配は未実行');
};

subtest 'Before: 問題点 — 配送手配失敗時に決済と在庫が残る' => sub {
    my $payment   = PaymentService->new;
    my $inventory = InventoryService->new;
    my $shipping  = ShippingService->new(should_fail => 1);
    my $processor = OrderProcessor->new(
        payment_service   => $payment,
        inventory_service => $inventory,
        shipping_service  => $shipping,
    );

    eval {
        $processor->process_order({
            amount   => 8000,
            item_id  => 'ITEM-003',
            quantity => 3,
            address  => 'Nagoya, Japan',
        });
    };
    like($@, qr/Shipping unavailable/, '配送手配でエラー');

    # 問題: 決済と在庫引当が成功したまま残っている
    is($payment->charge_count, 1, '決済は実行済み（返金されない！）');
    is($inventory->reservation_count, 1, '在庫引当は実行済み（解放されない！）');
    is($shipping->shipment_count, 0, '配送手配は失敗');
};

done_testing;

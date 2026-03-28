use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use Test::More;

do './agents/tests/code-detective-saga/after/lib.pl' or die $@ || $!;

subtest 'After: 正常系 — 全ステップ成功で注文完了' => sub {
    my $payment   = PaymentService->new;
    my $inventory = InventoryService->new;
    my $shipping  = ShippingService->new;
    my $saga = OrderSaga->new(
        payment_service   => $payment,
        inventory_service => $inventory,
        shipping_service  => $shipping,
    );

    my $result = $saga->execute({
        amount   => 5000,
        item_id  => 'ITEM-001',
        quantity => 2,
        address  => 'Tokyo, Japan',
    });

    is($result->{success}, 1, '注文成功');
    is($result->{payment}{amount}, 5000, '決済額が正しい');
    is($result->{reservation}{item_id}, 'ITEM-001', '在庫引当の商品IDが正しい');
    is($result->{shipment}{address}, 'Tokyo, Japan', '配送先が正しい');
    is($payment->refund_count, 0, '返金なし（成功時は補償不要）');
    is($inventory->release_count, 0, '在庫解放なし（成功時は補償不要）');
};

subtest 'After: 在庫引当失敗時に決済が自動返金される' => sub {
    my $payment   = PaymentService->new;
    my $inventory = InventoryService->new(should_fail => 1);
    my $shipping  = ShippingService->new;
    my $saga = OrderSaga->new(
        payment_service   => $payment,
        inventory_service => $inventory,
        shipping_service  => $shipping,
    );

    my $result = $saga->execute({
        amount   => 3000,
        item_id  => 'ITEM-002',
        quantity => 1,
        address  => 'Osaka, Japan',
    });

    is($result->{success}, 0, '注文失敗');
    is($result->{step}, 'inventory', '失敗箇所は在庫引当');
    is($payment->charge_count, 1, '決済は一度実行された');
    is($payment->refund_count, 1, '決済が自動返金された');
    is($inventory->reservation_count, 0, '在庫引当は失敗');
    is($shipping->shipment_count, 0, '配送手配は未実行');
};

subtest 'After: 配送手配失敗時に決済返金＋在庫解放が逆順で実行される' => sub {
    my $payment   = PaymentService->new;
    my $inventory = InventoryService->new;
    my $shipping  = ShippingService->new(should_fail => 1);
    my $saga = OrderSaga->new(
        payment_service   => $payment,
        inventory_service => $inventory,
        shipping_service  => $shipping,
    );

    my $result = $saga->execute({
        amount   => 8000,
        item_id  => 'ITEM-003',
        quantity => 3,
        address  => 'Nagoya, Japan',
    });

    is($result->{success}, 0, '注文失敗');
    is($result->{step}, 'shipping', '失敗箇所は配送手配');
    is($payment->charge_count, 1, '決済は一度実行された');
    is($payment->refund_count, 1, '決済が自動返金された');
    is($inventory->reservation_count, 1, '在庫引当は一度実行された');
    is($inventory->release_count, 1, '在庫が自動解放された');
    is($shipping->shipment_count, 0, '配送手配は失敗');
};

subtest 'After: 決済失敗時は補償不要' => sub {
    my $payment   = PaymentService->new(should_fail => 1);
    my $inventory = InventoryService->new;
    my $shipping  = ShippingService->new;
    my $saga = OrderSaga->new(
        payment_service   => $payment,
        inventory_service => $inventory,
        shipping_service  => $shipping,
    );

    my $result = $saga->execute({
        amount   => 1000,
        item_id  => 'ITEM-004',
        quantity => 1,
        address  => 'Fukuoka, Japan',
    });

    is($result->{success}, 0, '注文失敗');
    is($result->{step}, 'payment', '失敗箇所は決済');
    is($payment->charge_count, 0, '決済は実行されていない');
    is($inventory->reservation_count, 0, '在庫引当は未実行');
    is($shipping->shipment_count, 0, '配送手配は未実行');
};

subtest 'After: 複数注文で状態が干渉しない' => sub {
    my $payment   = PaymentService->new;
    my $inventory = InventoryService->new;
    my $shipping  = ShippingService->new;
    my $saga = OrderSaga->new(
        payment_service   => $payment,
        inventory_service => $inventory,
        shipping_service  => $shipping,
    );

    my $r1 = $saga->execute({ amount => 1000, item_id => 'A', quantity => 1, address => 'Tokyo' });
    my $r2 = $saga->execute({ amount => 2000, item_id => 'B', quantity => 2, address => 'Osaka' });

    is($r1->{success}, 1, '注文1成功');
    is($r2->{success}, 1, '注文2成功');
    is($payment->charge_count, 2, '決済が2回実行された');
    is($inventory->reservation_count, 2, '在庫引当が2回実行された');
    is($shipping->shipment_count, 2, '配送手配が2回実行された');
};

done_testing;

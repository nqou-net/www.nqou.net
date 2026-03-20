use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use Test::More;

do './agents/tests/code-detective-mediator-pattern/after/lib.pl' or die $@ || $!;

subtest 'After: Mediator Pattern' => sub {
    my $mediator = OrderMediator->new;

    my $order_mgr    = OrderManager->new;
    my $inventory    = InventoryManager->new;
    my $payment      = PaymentGateway->new;
    my $notification = NotificationService->new;
    my $audit        = AuditLogger->new;

    $mediator->register(order        => $order_mgr)
             ->register(inventory    => $inventory)
             ->register(payment      => $payment)
             ->register(notification => $notification)
             ->register(audit        => $audit);

    # 各モジュールに他モジュールへの直接参照がない
    ok(!$order_mgr->can('inventory'),    'OrderManager has no direct module references');
    ok(!$payment->can('inventory'),      'PaymentGateway has no direct module references');
    ok(!$inventory->can('notification'), 'InventoryManager has no direct module references');
    ok(!$notification->can('audit'),     'NotificationService has no direct module references');

    # 全モジュールが Mediator に登録済み
    is(scalar keys $mediator->colleagues->%*, 5, 'All 5 modules registered with Mediator');

    # order_placed イベントで全ワークフローが駆動
    my $order = { id => 'TS-001', item_id => 'HOODIE-BK-L', quantity => 1 };
    $order_mgr->place_order($order);

    ok(scalar $notification->messages->@* > 0, 'order_placed event triggers notification');
    ok(scalar $audit->logs->@* > 0, 'order_placed event triggers audit log');
    like($notification->messages->[0], qr/注文確定/, 'Notification contains order confirmation');

    # payment_failed イベントでロールバック
    my $mediator2     = OrderMediator->new;
    my $order_mgr2    = OrderManager->new;
    my $inventory2    = InventoryManager->new;
    my $payment2      = PaymentGateway->new(should_fail => 1);
    my $notification2 = NotificationService->new;
    my $audit2        = AuditLogger->new;

    $mediator2->register(order        => $order_mgr2)
              ->register(inventory    => $inventory2)
              ->register(payment      => $payment2)
              ->register(notification => $notification2)
              ->register(audit        => $audit2);

    my $order2 = { id => 'TS-002', item_id => 'TEE-WH-M', quantity => 1 };
    $order_mgr2->place_order($order2);

    my @fail_msgs = grep { /決済失敗/ } $notification2->messages->@*;
    ok(scalar @fail_msgs > 0, 'payment_failed event triggers rollback notification');

    # CouponEngine を追加（既存モジュール変更ゼロ）
    my $mediator3     = OrderMediator->new;
    my $order_mgr3    = OrderManager->new;
    my $inventory3    = InventoryManager->new;
    my $payment3      = PaymentGateway->new;
    my $notification3 = NotificationService->new;
    my $audit3        = AuditLogger->new;
    my $coupon        = CouponEngine->new;

    $mediator3->register(order        => $order_mgr3)
              ->register(inventory    => $inventory3)
              ->register(payment      => $payment3)
              ->register(notification => $notification3)
              ->register(audit        => $audit3)
              ->register(coupon       => $coupon);

    is(scalar keys $mediator3->colleagues->%*, 6, 'CouponEngine added without modifying existing modules');

    my $order3 = { id => 'TS-003', item_id => 'JACKET-NV-L', quantity => 1, coupon_code => 'SPRING50' };
    $order_mgr3->place_order($order3);

    is($order3->{discount}, 500, 'Coupon discount applied correctly');

    my @coupon_msgs = grep { /クーポン適用/ } $notification3->messages->@*;
    ok(scalar @coupon_msgs > 0, 'coupon_applied event triggers notification');

    my @coupon_logs = grep { $_->{event} eq 'coupon_applied' } $audit3->logs->@*;
    ok(scalar @coupon_logs > 0, 'coupon_applied event triggers audit log');
};

done_testing;

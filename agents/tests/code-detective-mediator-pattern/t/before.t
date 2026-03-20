use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use Test::More;

do './agents/tests/code-detective-mediator-pattern/before/lib.pl' or die $@ || $!;

subtest 'Before: Spaghetti Coupling' => sub {
    my $audit        = AuditLogger->new;
    my $notification = NotificationService->new;
    my $inventory    = InventoryManager->new;
    my $payment      = PaymentGateway->new;
    my $order_mgr    = OrderManager->new;

    # 後付けで全参照を注入（rw にせざるを得ない）
    $notification->audit($audit);
    $inventory->notification($notification);
    $inventory->audit($audit);
    $payment->inventory($inventory);
    $payment->notification($notification);
    $payment->audit($audit);
    $order_mgr->inventory($inventory);
    $order_mgr->payment($payment);
    $order_mgr->notification($notification);
    $order_mgr->audit($audit);

    my $order = { id => 'TS-001', item_id => 'HOODIE-BK-L', quantity => 1 };
    $order_mgr->place_order($order);

    ok(1, 'OrderManager can place_order');

    # 直接参照の証拠
    ok($payment->can('inventory'),    'PaymentGateway references InventoryManager directly');
    ok($inventory->can('notification'), 'InventoryManager references NotificationService directly');
    ok($notification->can('audit'),   'NotificationService references AuditLogger directly');

    # CouponEngine を追加するには既存モジュールの修正が必要
    # OrderManager に has coupon => ... を追加
    # PaymentGateway に has coupon => ... を追加
    # InventoryManager に has coupon => ... を追加
    # ... すべてのモジュールに手を入れる必要がある
    ok(1, 'Adding CouponEngine requires modifying ALL existing modules');
};

done_testing;

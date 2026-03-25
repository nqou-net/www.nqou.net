use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use Test::More;

do './agents/tests/code-detective-unit-of-work/before/lib.pl' or die $@ || $!;

sub make_service ($db, $fail_inventory = 0) {
    return OrderService->new(
        _order_repo     => OrderRepository->new(_db => $db),
        _inventory_repo => InventoryRepository->new(_db => $db, _fail => $fail_inventory),
        _payment_repo   => PaymentRepository->new(_db => $db),
    );
}

subtest 'Before: 正常系 — 3つの保存がすべて成功する' => sub {
    my $db = InMemoryDB->new(inventory => { 'ITEM-001' => 10 });
    my $svc = make_service($db);

    my $order = $svc->create_order(
        item_id  => 'ITEM-001',
        quantity => 3,
        user_id  => 'USR-001',
        amount   => 3000,
    );

    is($order->{id},                     'ORD-1', '注文IDが正しい');
    is(scalar @{ $db->orders },          1,       '注文が1件保存されている');
    is($db->inventory->{'ITEM-001'},     7,       '在庫が3個減った');
    is(scalar @{ $db->payments },        1,       '支払いが保存されている');
    is($db->payments->[0]{amount},       3000,    '支払い金額が正しい');
};

subtest 'Before: 在庫不足では全保存が行われない（バリデーション）' => sub {
    my $db = InMemoryDB->new(inventory => { 'ITEM-001' => 2 });
    my $svc = make_service($db);

    eval {
        $svc->create_order(
            item_id  => 'ITEM-001',
            quantity => 5,
            user_id  => 'USR-001',
            amount   => 5000,
        );
    };

    like($@, qr/在庫不足/, '在庫不足でエラー');
    is(scalar @{ $db->orders },   1, '注文は保存されてしまっている（在庫チェック前にsave）');
};

subtest 'Before: PROBLEM — 在庫更新が失敗すると注文だけが宙に浮く' => sub {
    my $db = InMemoryDB->new(inventory => { 'ITEM-001' => 10 });
    my $svc = make_service($db, 1);  # 在庫リポジトリを強制障害モードに

    eval {
        $svc->create_order(
            item_id  => 'ITEM-001',
            quantity => 3,
            user_id  => 'USR-001',
            amount   => 3000,
        );
    };

    ok($@, 'エラーが発生した');
    is(scalar @{ $db->orders },      1,  'PROBLEM: 注文は保存されてしまっている');
    is($db->inventory->{'ITEM-001'}, 10, '在庫は変わっていない（不整合！）');
    is(scalar @{ $db->payments },    0,  '支払いは保存されていない（さらなる不整合）');
};

done_testing;

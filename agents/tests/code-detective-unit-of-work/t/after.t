use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use Test::More;

do './agents/tests/code-detective-unit-of-work/after/lib.pl' or die $@ || $!;

subtest 'After: 正常系 — 3つの変更が一括コミットされる' => sub {
    my $db = InMemoryDB->new(inventory => { 'ITEM-001' => 10 });
    my $svc = OrderService->new(_db => $db);

    my $order = $svc->create_order(
        item_id  => 'ITEM-001',
        quantity => 3,
        user_id  => 'USR-001',
        amount   => 3000,
    );

    isa_ok($order, 'OrderRecord', '戻り値はOrderRecordオブジェクト');
    is(scalar @{ $db->orders },      1,    '注文が1件保存されている');
    is($db->inventory->{'ITEM-001'}, 7,    'FIX: 在庫が3個減った');
    is(scalar @{ $db->payments },    1,    '支払いが保存されている');
    is($db->payments->[0]{amount},   3000, '支払い金額が正しい');
};

subtest 'After: 在庫不足ではすべて保存されない' => sub {
    my $db = InMemoryDB->new(inventory => { 'ITEM-001' => 2 });
    my $svc = OrderService->new(_db => $db);

    eval {
        $svc->create_order(
            item_id  => 'ITEM-001',
            quantity => 5,
            user_id  => 'USR-001',
            amount   => 5000,
        );
    };

    like($@, qr/在庫不足/, '在庫不足でエラー');
    is(scalar @{ $db->orders },   0, 'FIX: 注文は保存されていない');
    is(scalar @{ $db->payments }, 0, 'FIX: 支払いも保存されていない');
};

subtest 'After: FIX — 在庫更新が失敗すると全変更がロールバックされる' => sub {
    my $db = InMemoryDB->new(inventory => { 'ITEM-001' => 10 });
    my $svc = OrderService->new(_db => $db, _fail_inventory => 1);

    eval {
        $svc->create_order(
            item_id  => 'ITEM-001',
            quantity => 3,
            user_id  => 'USR-001',
            amount   => 3000,
        );
    };

    ok($@, 'エラーが発生した');
    is(scalar @{ $db->orders },      0,  'FIX: 注文は保存されていない（ロールバック済み）');
    is($db->inventory->{'ITEM-001'}, 10, 'FIX: 在庫も元に戻っている');
    is(scalar @{ $db->payments },    0,  'FIX: 支払いも保存されていない');
};

subtest 'After: UnitOfWork の構造 — 責任が明確に分離されている' => sub {
    my $db  = InMemoryDB->new;
    my $uow = UnitOfWork->new(_db => $db);

    ok($uow->can('register_new'),   'UnitOfWork: register_new が存在');
    ok($uow->can('register_dirty'), 'UnitOfWork: register_dirty が存在');
    ok($uow->can('commit'),         'UnitOfWork: commit が存在');

    # OrderService は直接 DB に書かない
    my $svc = OrderService->new(_db => $db);
    ok(!$svc->can('save'),          'FIX: OrderService が直接 save しない');
};

done_testing;

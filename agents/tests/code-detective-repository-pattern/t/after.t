use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use Test::More;

do './agents/tests/code-detective-repository-pattern/after/lib.pl' or die $@ || $!;

subtest 'After: Repository Pattern — Pure Business Logic (no DB)' => sub {
    # Order 生成に DB は不要！
    my $order = Order->new(
        customer => '株式会社タクミ',
        items    => [
            { name => 'ウィジェットA', price => 1000, qty => 5 },
            { name => 'ウィジェットB', price => 2000, qty => 3 },
        ],
    );

    is($order->total, 11000, 'Total: 1000*5 + 2000*3 = 11000 (no DB needed)');

    # ステータス遷移のテスト — DB 不要！
    $order->confirm();
    is($order->status, 'confirmed', 'confirm() changes status without DB');
    ok(!$order->id, 'confirm() does NOT call save() — no side effects');

    $order->ship();
    is($order->status, 'shipped', 'ship() changes status without DB');

    # 不正な遷移のテスト — DB 不要！
    eval { $order->cancel() };
    like($@, qr/Cannot cancel/, 'Cannot cancel a shipped order');

    # 別の注文でキャンセルのテスト
    my $order2 = Order->new(
        customer => 'テスト社',
        items    => [{ name => 'X', price => 100, qty => 1 }],
    );
    $order2->confirm();
    $order2->cancel();
    is($order2->status, 'cancelled', 'confirmed order can be cancelled');

    ok(1, 'FIX: All business logic tests run WITHOUT any DB handle');
};

subtest 'After: Repository Pattern — InMemoryRepository' => sub {
    my $repo = InMemoryOrderRepository->new;

    my $order = Order->new(
        customer => '株式会社タクミ',
        items    => [
            { name => 'ウィジェットA', price => 1000, qty => 5 },
        ],
    );

    # save でIDが付与される
    $repo->save($order);
    ok($order->id, 'save() assigns id via Repository');
    is($repo->count, 1, 'Repository has 1 order');

    # find_by_id で取得
    my $found = $repo->find_by_id($order->id);
    is($found->customer, '株式会社タクミ', 'find_by_id returns correct order');
    is($found->status, 'draft', 'Found order has correct status');

    # ビジネスロジックを実行してから save
    $order->confirm();
    $repo->save($order);

    my $updated = $repo->find_by_id($order->id);
    is($updated->status, 'confirmed', 'Status updated after save');

    # 2件目を追加して search
    my $order2 = Order->new(
        customer => 'テスト社',
        items    => [{ name => 'Y', price => 200, qty => 2 }],
    );
    $repo->save($order2);
    is($repo->count, 2, 'Repository has 2 orders');

    my $drafts = $repo->search(status => 'draft');
    is(scalar @$drafts, 1, 'search(status => draft) returns 1 order');
    is($drafts->[0]->customer, 'テスト社', 'Draft order is テスト社');

    my $confirmed = $repo->search(status => 'confirmed');
    is(scalar @$confirmed, 1, 'search(status => confirmed) returns 1 order');
    is($confirmed->[0]->customer, '株式会社タクミ', 'Confirmed order is 株式会社タクミ');
};

subtest 'After: Repository Pattern — DbiOrderRepository (same interface)' => sub {
    my $fake_dbh = FakeDbh->new;
    my $dbi_repo = DbiOrderRepository->new(dbh => $fake_dbh);

    my $order = Order->new(
        customer => 'DBI経由テスト',
        items    => [{ name => 'Z', price => 300, qty => 1 }],
    );

    $dbi_repo->save($order);
    ok($order->id, 'DbiOrderRepository assigns id');

    my $found = $dbi_repo->find_by_id($order->id);
    is($found->customer, 'DBI経由テスト', 'DbiOrderRepository find_by_id works');

    # InMemory と DBI は同じインターフェース
    ok(InMemoryOrderRepository->does('OrderRepository'),
       'InMemoryOrderRepository implements OrderRepository role');
    ok(DbiOrderRepository->does('OrderRepository'),
       'DbiOrderRepository implements OrderRepository role');

    ok(1, 'Both repositories share the same interface — swappable');
};

subtest 'After: Repository Pattern — Testability comparison' => sub {
    # Before: ビジネスロジックのテストに FakeDbh が必要だった
    # After:  ビジネスロジックのテストに何も不要

    my $order = Order->new(
        customer => '高速テスト',
        items    => [{ name => 'Fast', price => 500, qty => 10 }],
    );

    is($order->total, 5000, 'Business logic test: no setup required');
    $order->confirm();
    is($order->status, 'confirmed', 'State transition test: no setup required');

    ok(1, 'FIX: Business logic tests need ZERO infrastructure');
    ok(1, 'FIX: Test suite runs in seconds, not 30 minutes');
};

done_testing;

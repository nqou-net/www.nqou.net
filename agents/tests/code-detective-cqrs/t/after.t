use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use Test::More;

do './agents/tests/code-detective-cqrs/after/lib.pl' or die $@ || $!;

subtest 'After: Command側 — 受注登録（バリデーション付き）' => sub {
    my $cmd = SalesOrderCommandRepository->new;
    my $order = $cmd->register(
        customer_id => 'CUST-001',
        amount      => 5000,
        items       => ['商品A', '商品B'],
    );
    isa_ok($order, 'SalesOrder', '戻り値はSalesOrderオブジェクト');
    is($order->customer_id, 'CUST-001', '顧客IDが正しい');
    is($order->amount,      5000,       '金額が正しい');
    is($order->status,      'pending',  '初期ステータスはpending');
};

subtest 'After: Command側 — バリデーション' => sub {
    my $cmd = SalesOrderCommandRepository->new;
    eval { $cmd->register(amount => 1000, items => ['X']) };
    like($@, qr/顧客ID/, '顧客IDなしでエラー');

    eval { $cmd->register(customer_id => 'C', amount => 0, items => ['X']) };
    like($@, qr/金額/, '金額0でエラー');

    eval { $cmd->register(customer_id => 'C', amount => 100) };
    like($@, qr/商品/, '商品なしでエラー');
};

subtest 'After: Command側 — ステータス変更' => sub {
    my $cmd = SalesOrderCommandRepository->new;
    my $order = $cmd->register(
        customer_id => 'CUST-001',
        amount      => 1000,
        items       => ['商品X'],
    );
    $cmd->complete($order->id);
    is($order->status, 'completed', 'FIX: ステータスがcompletedになった');
};

subtest 'After: Query側 — 集計クエリ（CommandRepositoryに依存）' => sub {
    my $cmd = SalesOrderCommandRepository->new;
    $cmd->register(customer_id => 'CUST-001', amount => 3000, items => ['A']);
    $cmd->register(customer_id => 'CUST-001', amount => 2000, items => ['B']);
    $cmd->register(customer_id => 'CUST-002', amount => 8000, items => ['C']);

    my $qry = SalesOrderQueryService->new(_command_repo => $cmd);

    is($qry->total_by_customer('CUST-001'), 5000, 'FIX: 顧客001の合計は5000');
    is($qry->total_by_customer('CUST-002'), 8000, 'FIX: 顧客002の合計は8000');

    my $s = $qry->summary;
    is($s->{count},   3,     'FIX: 受注数は3件');
    is($s->{total},   13000, 'FIX: 合計金額は13000');
    is($s->{pending}, 3,     'FIX: 保留件数は3件');
};

subtest 'After: FIX — CommandとQueryの責任が完全に分離されている' => sub {
    my $cmd = SalesOrderCommandRepository->new;
    my $qry = SalesOrderQueryService->new(_command_repo => $cmd);

    # Command側にQueryメソッドが存在しない
    ok( $cmd->can('register'),           'Command: register が存在');
    ok( $cmd->can('complete'),           'Command: complete が存在');
    ok(!$cmd->can('total_by_customer'),  'FIX: CommandにQueryメソッドが混入していない');
    ok(!$cmd->can('pending_orders'),     'FIX: CommandにQueryメソッドが混入していない');
    ok(!$cmd->can('summary'),            'FIX: CommandにQueryメソッドが混入していない');

    # Query側にCommandメソッドが存在しない
    ok( $qry->can('total_by_customer'), 'Query: total_by_customer が存在');
    ok( $qry->can('pending_orders'),    'Query: pending_orders が存在');
    ok( $qry->can('summary'),           'Query: summary が存在');
    ok(!$qry->can('register'),          'FIX: QueryにCommandメソッドが混入していない');
    ok(!$qry->can('complete'),          'FIX: QueryにCommandメソッドが混入していない');
};

subtest 'After: FIX — Queryのロジック変更がCommandに影響しない' => sub {
    # CommandRepositoryのテストはQueryServiceの変更に影響されない
    my $cmd = SalesOrderCommandRepository->new;
    my $order = $cmd->register(
        customer_id => 'ISOLATED-TEST',
        amount      => 9999,
        items       => ['独立したテスト商品'],
    );
    # バリデーションロジックはQuery側の変更に左右されない
    is($order->amount, 9999, 'FIX: Command側のテストはQuery側変更に無関係');
};

done_testing;

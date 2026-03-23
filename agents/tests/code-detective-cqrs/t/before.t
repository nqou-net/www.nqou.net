use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use Test::More;

do './agents/tests/code-detective-cqrs/before/lib.pl' or die $@ || $!;

subtest 'Before: 受注登録（基本動作）' => sub {
    my $repo = SalesOrderRepository->new;
    my $order = $repo->register(
        customer_id => 'CUST-001',
        amount      => 5000,
        items       => ['商品A', '商品B'],
    );
    is($order->{customer_id}, 'CUST-001', '顧客IDが正しい');
    is($order->{amount},      5000,       '金額が正しい');
    is($order->{status},      'pending',  '初期ステータスはpending');
};

subtest 'Before: バリデーション' => sub {
    my $repo = SalesOrderRepository->new;
    eval { $repo->register(amount => 1000, items => ['X']) };
    like($@, qr/顧客ID/, '顧客IDなしでエラー');

    eval { $repo->register(customer_id => 'C', amount => 0, items => ['X']) };
    like($@, qr/金額/, '金額0でエラー');

    eval { $repo->register(customer_id => 'C', amount => 100) };
    like($@, qr/商品/, '商品なしでエラー');
};

subtest 'Before: 集計クエリ' => sub {
    my $repo = SalesOrderRepository->new;
    $repo->register(customer_id => 'CUST-001', amount => 3000, items => ['A']);
    $repo->register(customer_id => 'CUST-001', amount => 2000, items => ['B']);
    $repo->register(customer_id => 'CUST-002', amount => 8000, items => ['C']);

    is($repo->total_by_customer('CUST-001'), 5000, '顧客001の合計は5000');
    is($repo->total_by_customer('CUST-002'), 8000, '顧客002の合計は8000');

    my $s = $repo->summary;
    is($s->{count},   3, '受注数は3件');
    is($s->{total},   13000, '合計金額は13000');
    is($s->{pending}, 3, '保留件数は3件');
};

subtest 'Before: PROBLEM — 読み書きが同一クラスに混在している' => sub {
    # 同じクラスが書き込みも読み取りも担当している
    my $repo = SalesOrderRepository->new;
    ok($repo->can('register'),          'Commandメソッド: register が存在');
    ok($repo->can('complete_order'),    'Commandメソッド: complete_order が存在');
    ok($repo->can('total_by_customer'), 'Queryメソッド: total_by_customer が存在');
    ok($repo->can('pending_orders'),    'Queryメソッド: pending_orders が存在');
    ok($repo->can('summary'),           'Queryメソッド: summary が存在');

    # 同一オブジェクトに責任が混在している
    my $all_methods = [qw(register complete_order total_by_customer pending_orders summary)];
    is(scalar @$all_methods, 5, 'PROBLEM: 5つの責任が1クラスに詰め込まれている');
};

done_testing;

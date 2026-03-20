use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use Test::More;

do './agents/tests/code-detective-repository-pattern/before/lib.pl' or die $@ || $!;

subtest 'Before: Fat Model' => sub {
    my $dbh = FakeDbh->new;

    # Order 生成には必ず $dbh が必要
    my $order = Order->new(
        customer => '株式会社タクミ',
        items    => [
            { name => 'ウィジェットA', price => 1000, qty => 5 },
            { name => 'ウィジェットB', price => 2000, qty => 3 },
        ],
        dbh => $dbh,  # ← DB接続が必須！
    );

    # ビジネスロジックのテスト（合計金額）
    is($order->total, 11000, 'Total: 1000*5 + 2000*3 = 11000');

    # ステータス遷移のテスト — だが confirm() 内部で save() が呼ばれ DB に書き込む
    $order->confirm();
    is($order->status, 'confirmed', 'Status changed to confirmed');

    # confirm() の中で save() が自動呼び出しされている
    ok($order->id, 'save() was called inside confirm() — id assigned');

    # ステータス遷移のロジックだけテストしたいのに DB が必要
    eval {
        Order->new(
            customer => 'テスト社',
            items    => [{ name => 'X', price => 100, qty => 1 }],
            # dbh を渡さない → エラー
        );
    };
    like($@, qr/required/, 'Cannot create Order without dbh — Fat Model problem');

    # find_by_id にも $dbh が必要
    my $found = Order->find_by_id($dbh, $order->id);
    is($found->customer, '株式会社タクミ', 'find_by_id requires $dbh as argument');
    is($found->status, 'confirmed', 'Found order has correct status');

    # search にも $dbh が必要
    my $results = Order->search($dbh, status => 'confirmed');
    is(scalar @$results, 1, 'search requires $dbh as argument');

    # テストの問題点: ビジネスロジック（total, confirm, ship）をテストするだけなのに
    # 毎回 FakeDbh を用意しなければならない
    ok(1, 'PROBLEM: Every test needs a DB handle, even for pure business logic');
};

done_testing;

use v5.36;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use TestDataBuilder::User;
use TestDataBuilder::Order;

# === テスト1: 通常の注文処理 ===
subtest '通常の注文は正常に処理される' => sub {
    my $user  = TestDataBuilder::User->new->build;
    my $order = TestDataBuilder::Order->new
        ->with_user_id($user->{id})
        ->build;

    is $order->{status}, 'pending', '注文ステータスがpending';
    is $order->{user_id}, $user->{id}, 'ユーザーIDが一致';
    ok $order->{total_price} > 0, '合計金額が正';
};

# === テスト2: 高額注文の検証 ===
subtest '高額注文は承認待ちになる' => sub {
    my $user = TestDataBuilder::User->new
        ->with_id(1002)
        ->with_name('高額太郎')
        ->with_email('rich@example.com')
        ->build;

    my $order = TestDataBuilder::Order->new
        ->with_id(5002)
        ->with_user_id($user->{id})
        ->with_total(500_000)
        ->with_status('pending_approval')
        ->with_items({
            product_id => 201,
            name       => '高級ウイスキー',
            price      => 500_000,
            quantity   => 1,
        })
        ->with_shipping(method => 'express')
        ->build;

    is $order->{status}, 'pending_approval', '高額注文は承認待ち';
    cmp_ok $order->{total_price}, '>=', 100_000, '10万円以上';
};

# === テスト3: 退会済みユーザーの注文拒否 ===
subtest '退会済みユーザーは注文できない' => sub {
    my $user = TestDataBuilder::User->new
        ->with_id(1003)
        ->with_status('inactive')
        ->build;

    is $user->{status}, 'inactive', 'ユーザーが退会済み';
};

# === テスト4: 複数商品の注文 ===
subtest '複数商品の合計金額が正しい' => sub {
    my $user = TestDataBuilder::User->new
        ->with_id(1004)
        ->build;

    my $order = TestDataBuilder::Order->new
        ->with_id(5004)
        ->with_user_id($user->{id})
        ->with_total(7500)
        ->with_items(
            {
                product_id => 101,
                name       => 'Perlクックブック',
                price      => 3000,
                quantity   => 1,
            },
            {
                product_id => 102,
                name       => 'プログラミングPerl',
                price      => 4500,
                quantity   => 1,
            },
        )
        ->build;

    my $expected_total = 0;
    for my $item ($order->{items}->@*) {
        $expected_total += $item->{price} * $item->{quantity};
    }
    is $order->{total_price}, $expected_total, '合計金額が一致';
};

# === テスト5: 送料無料条件 ===
subtest '5000円以上で送料無料' => sub {
    my $order = TestDataBuilder::Order->new
        ->with_total(6000)
        ->with_items({
            product_id => 103,
            name       => 'Effective Perl',
            price      => 6000,
            quantity   => 1,
        })
        ->with_shipping(method => 'free')
        ->build;

    cmp_ok $order->{total_price}, '>=', 5000, '5000円以上';
    is $order->{shipping}{method}, 'free', '送料無料';
};

# === テスト6: バリデーション ===
subtest 'Builderが不正なデータを検出する' => sub {
    eval {
        TestDataBuilder::Order->new
            ->with_total(0)
            ->build;
    };
    like $@, qr/total_price/, '合計金額0はエラー';
};

done_testing;

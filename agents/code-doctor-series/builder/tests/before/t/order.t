use v5.36;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use OrderFixture;

# === テスト1: 通常の注文処理 ===
subtest '通常の注文は正常に処理される' => sub {
    # テストデータをコピペして微調整…
    my $user = {
        id         => 1001,
        name       => 'テスト太郎',
        email      => 'test@example.com',
        age        => 30,
        address    => '東京都渋谷区',
        phone      => '090-1234-5678',
        created_at => '2025-01-01T00:00:00+09:00',
        status     => 'active',
    };
    my $order = {
        id          => 5001,
        user_id     => 1001,
        total_price => 3000,
        status      => 'pending',
        ordered_at  => '2025-06-15T10:30:00+09:00',
        items       => [
            {
                product_id => 101,
                name       => 'Perlクックブック',
                price      => 3000,
                quantity   => 1,
            },
        ],
        shipping => {
            zipcode    => '150-0001',
            address    => '東京都渋谷区神宮前1-1-1',
            method     => 'standard',
        },
    };

    is $order->{status}, 'pending', '注文ステータスがpending';
    is $order->{user_id}, $user->{id}, 'ユーザーIDが一致';
    ok $order->{total_price} > 0, '合計金額が正';
};

# === テスト2: 高額注文の検証 ===
subtest '高額注文は承認待ちになる' => sub {
    my $user = {
        id         => 1002,
        name       => '高額太郎',
        email      => 'rich@example.com',
        age        => 45,
        address    => '東京都港区',
        phone      => '090-9999-0000',
        created_at => '2025-01-01T00:00:00+09:00',
        status     => 'active',  # ← スキーマ変更でここが 'verified' に変わったのに修正漏れ
    };
    my $order = {
        id          => 5002,
        user_id     => 1002,
        total_price => 500_000,
        status      => 'pending_approval',
        ordered_at  => '2025-06-15T14:00:00+09:00',
        items       => [
            {
                product_id => 201,
                name       => '高級ウイスキー',
                price      => 500_000,
                quantity   => 1,
            },
        ],
        shipping => {
            zipcode    => '106-0032',
            address    => '東京都港区六本木1-1-1',
            method     => 'express',
        },
    };

    is $order->{status}, 'pending_approval', '高額注文は承認待ち';
    cmp_ok $order->{total_price}, '>=', 100_000, '10万円以上';
};

# === テスト3: 退会済みユーザーの注文拒否 ===
subtest '退会済みユーザーは注文できない' => sub {
    my $user = {
        id         => 1003,
        name       => '退会太郎',
        email      => 'quit@example.com',
        age        => 28,
        address    => '大阪府大阪市',
        phone      => '080-1111-2222',
        created_at => '2024-06-01T00:00:00+09:00',
        status     => 'inactive',
    };
    # 退会済みユーザーは注文不可
    is $user->{status}, 'inactive', 'ユーザーが退会済み';
};

# === テスト4: 複数商品の注文 ===
subtest '複数商品の合計金額が正しい' => sub {
    my $user = {
        id         => 1004,
        name       => '複数太郎',
        email      => 'multi@example.com',
        age        => 35,
        address    => '神奈川県横浜市',
        phone      => '090-3333-4444',
        created_at => '2025-03-01T00:00:00+09:00',
        status     => 'active',
    };
    my $order = {
        id          => 5004,
        user_id     => 1004,
        total_price => 7500,
        status      => 'pending',
        ordered_at  => '2025-06-16T09:00:00+09:00',
        items       => [
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
        ],
        shipping => {
            zipcode    => '220-0001',
            address    => '神奈川県横浜市西区1-1-1',
            method     => 'standard',
        },
    };

    my $expected_total = 0;
    for my $item ($order->{items}->@*) {
        $expected_total += $item->{price} * $item->{quantity};
    }
    is $order->{total_price}, $expected_total, '合計金額が一致';
};

# === テスト5: 送料無料条件 ===
subtest '5000円以上で送料無料' => sub {
    my $user = {
        id         => 1005,
        name       => '送料太郎',
        email      => 'free@example.com',
        age        => 40,
        address    => '東京都新宿区',
        phone      => '090-5555-6666',
        created_at => '2025-02-01T00:00:00+09:00',
        status     => 'active',
    };
    my $order = {
        id          => 5005,
        user_id     => 1005,
        total_price => 6000,
        status      => 'pending',
        ordered_at  => '2025-06-16T12:00:00+09:00',
        items       => [
            {
                product_id => 103,
                name       => 'Effective Perl',
                price      => 6000,
                quantity   => 1,
            },
        ],
        shipping => {
            zipcode    => '160-0001',
            address    => '東京都新宿区歌舞伎町1-1-1',
            method     => 'free',
        },
    };

    cmp_ok $order->{total_price}, '>=', 5000, '5000円以上';
    is $order->{shipping}{method}, 'free', '送料無料';
};

done_testing;

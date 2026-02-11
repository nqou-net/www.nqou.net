package OrderFixture;
use v5.36;

# テストデータ生成ユーティリティ
# TODO: もっといい方法があるはずだけど、動いてるし…
# FIXME: スキーマが変わるたびに全部直す必要あり（泣）

sub create_default_user {
    return {
        id         => 1001,
        name       => 'テスト太郎',
        email      => 'test@example.com',
        age        => 30,
        address    => '東京都渋谷区',
        phone      => '090-1234-5678',
        created_at => '2025-01-01T00:00:00+09:00',
        status     => 'active',
    };
}

sub create_default_order {
    return {
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
}

1;

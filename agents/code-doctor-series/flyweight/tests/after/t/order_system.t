use v5.36;
use Test::More;
use lib 'lib';
use OrderSystem;

# === テスト1: 基本的な注文処理 ===
subtest '基本的な注文と小計' => sub {
    my $sys   = OrderSystem->new;
    my $order = $sys->add_order(
        menu_name     => '生ビール',
        menu_price    => 550,
        menu_calorie  => 150,
        menu_category => 'ドリンク',
        table_no      => 1,
        quantity      => 2,
    );
    is $order->subtotal,  1100,                     '生ビール2杯 = 1100円';
    is $order->to_string, 'テーブル1: 生ビール x2 = ¥1100', '注文文字列';
};

# === テスト2: テーブル別集計 ===
subtest 'テーブル別合計' => sub {
    my $sys = OrderSystem->new;
    $sys->add_order(
        menu_name     => '生ビール',
        menu_price    => 550,
        menu_calorie  => 150,
        menu_category => 'ドリンク',
        table_no      => 1,
        quantity      => 3
    );
    $sys->add_order(
        menu_name     => '焼き鳥盛り',
        menu_price    => 980,
        menu_calorie  => 450,
        menu_category => 'フード',
        table_no      => 1,
        quantity      => 1
    );
    $sys->add_order(
        menu_name     => '生ビール',
        menu_price    => 550,
        menu_calorie  => 150,
        menu_category => 'ドリンク',
        table_no      => 2,
        quantity      => 2
    );

    is $sys->total_by_table(1), 2630, 'テーブル1: 1650+980=2630';
    is $sys->total_by_table(2), 1100, 'テーブル2: 1100';
};

# === テスト3: Flyweightでオブジェクト共有 ===
subtest 'MenuItemオブジェクトの共有（Flyweight）' => sub {
    my $sys = OrderSystem->new;

    # 同じ「生ビール」を10テーブルで注文
    for my $table (1 .. 10) {
        $sys->add_order(
            menu_name     => '生ビール',
            menu_price    => 550,
            menu_calorie  => 150,
            menu_category => 'ドリンク',
            table_no      => $table,
            quantity      => 1,
        );
    }

    # Flyweight: メニューオブジェクトは1つだけ
    is $sys->count_menu_objects, 1, '10テーブルでも生ビールオブジェクトは1つ（Flyweight）';

    # 全注文が同一オブジェクトを参照していることを確認
    my @orders     = $sys->orders;
    my $first_item = $orders[0]->menu_item;
    for my $order (@orders) {
        is $order->menu_item, $first_item, '同一オブジェクトを参照';
    }
};

# === テスト4: 価格改定が全注文に即座に反映 ===
subtest '価格改定の一括反映' => sub {
    my $sys = OrderSystem->new;
    $sys->add_order(
        menu_name     => '生ビール',
        menu_price    => 550,
        menu_calorie  => 150,
        menu_category => 'ドリンク',
        table_no      => $_,
        quantity      => 1
    ) for 1 .. 5;

    # プールの1箇所を変更するだけ
    $sys->update_price('生ビール', 600);

    # 全注文に自動反映
    for my $order ($sys->orders) {
        is $order->menu_item->price, 600, '価格が600に反映されている';
    }
    is $sys->total_by_table(1), 600, 'テーブル1の合計も即時更新';
};

# === テスト5: 複数メニューのプール管理 ===
subtest '複数メニューのプール' => sub {
    my $sys = OrderSystem->new;
    $sys->add_order(
        menu_name     => '生ビール',
        menu_price    => 550,
        menu_calorie  => 150,
        menu_category => 'ドリンク',
        table_no      => 1,
        quantity      => 3
    );
    $sys->add_order(
        menu_name     => '焼き鳥盛り',
        menu_price    => 980,
        menu_calorie  => 450,
        menu_category => 'フード',
        table_no      => 1,
        quantity      => 1
    );
    $sys->add_order(
        menu_name     => '生ビール',
        menu_price    => 550,
        menu_calorie  => 150,
        menu_category => 'ドリンク',
        table_no      => 2,
        quantity      => 2
    );
    $sys->add_order(
        menu_name     => 'ハイボール',
        menu_price    => 480,
        menu_calorie  => 100,
        menu_category => 'ドリンク',
        table_no      => 2,
        quantity      => 1
    );
    $sys->add_order(
        menu_name     => '焼き鳥盛り',
        menu_price    => 980,
        menu_calorie  => 450,
        menu_category => 'フード',
        table_no      => 3,
        quantity      => 2
    );

    # 5注文だがメニュー種類は3つだけ
    is $sys->count_menu_objects, 3, 'プール内のメニューは3種類のみ';
    ok $sys->pool->has('生ビール'),  'プールに生ビールあり';
    ok $sys->pool->has('焼き鳥盛り'), 'プールに焼き鳥盛りあり';
    ok $sys->pool->has('ハイボール'), 'プールにハイボールあり';
};

done_testing;

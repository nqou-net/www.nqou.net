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

# === テスト3: オブジェクト重複問題の可視化 ===
subtest 'MenuItemのオブジェクト重複' => sub {
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

    # 本来1つで済むはずの生ビールオブジェクトが10個存在する
    is $sys->count_menu_objects, 10, '同じメニューなのにオブジェクトが10個（これが問題）';
};

# === テスト4: 価格改定の問題 ===
subtest '価格改定の全走査' => sub {
    my $sys = OrderSystem->new;
    $sys->add_order(
        menu_name     => '生ビール',
        menu_price    => 550,
        menu_calorie  => 150,
        menu_category => 'ドリンク',
        table_no      => $_,
        quantity      => 1
    ) for 1 .. 5;

    my $updated = $sys->update_price('生ビール', 600);
    is $updated, 5, '5つの注文を個別に更新する必要がある';

    # 全部更新されたか確認
    for my $order ($sys->orders) {
        is $order->menu_item->price, 600, '価格が600に更新されている';
    }
};

done_testing;

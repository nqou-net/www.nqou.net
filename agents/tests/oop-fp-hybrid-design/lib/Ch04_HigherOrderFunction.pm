package Ch04_HigherOrderFunction;
use v5.36;
use List::Util qw(reduce sum);
use Exporter 'import';
our @EXPORT_OK = qw(
    process_items_imperative
    process_items_declarative
    filter_available_items
    calculate_totals_by_category
);

# 第4回: 高階関数（map/grep/reduce）で宣言的に書く
# ネストしたforeachループ vs 宣言的なパイプライン

# 問題版: 命令的なforeachループ（3重ネスト）
sub process_items_imperative ($orders) {
    my @result;

    for my $order (@$orders) {
        for my $item ($order->{items}->@*) {
            if ($item->{in_stock}) {
                for my $i (1 .. $item->{quantity}) {
                    my %processed = (
                        order_id   => $order->{id},
                        item_name  => $item->{name},
                        unit_price => $item->{price},
                        sequence   => $i,
                    );
                    push @result, \%processed;
                }
            }
        }
    }

    # さらに合計計算も命令的に...
    my $total = 0;
    for my $r (@result) {
        $total += $r->{unit_price};
    }

    return {items => \@result, total => $total};
}

# 解決版: map/grep/reduceによる宣言的な処理

sub filter_available_items ($items) {

    # grep: 条件に合う要素を抽出
    return [grep { $_->{in_stock} } @$items];
}

sub expand_quantities ($items) {

    # map + flat: 各アイテムを数量分に展開
    return [
        map {
            my $item = $_;
            map { {item_name => $item->{name}, unit_price => $item->{price}, sequence => $_,} }
                (1 .. $item->{quantity})
        } @$items
    ];
}

sub process_items_declarative ($orders) {

    # 宣言的パイプライン: 何をするかを記述
    my @all_items = map { $_->{id}, $_ }    # 注文IDを付与
        map {
        my $order = $_;
        map {
            { %$_, order_id => $order->{id} }
        } filter_available_items($order->{items})->@*
        } @$orders;

    my @expanded = map {
        my $item = $_;
        map { {order_id => $item->{order_id}, item_name => $item->{name}, unit_price => $item->{price}, sequence => $_,} }
            (1 .. $item->{quantity})
    } @all_items;

    # reduce: 畳み込みで合計計算
    my $total = reduce { $a + $b->{unit_price} } 0, @expanded;

    return {items => \@expanded, total => $total};
}

# より洗練された例: カテゴリ別集計
sub calculate_totals_by_category ($items) {

    # reduce で集約（純粋関数的アプローチ）
    my $by_category = reduce {
        my $cat = $b->{category} // 'other';
        $a->{$cat} //= 0;
        $a->{$cat} += $b->{price} * $b->{quantity};
        $a;
    } {}, @$items;

    return $by_category;
}

# デモ: 宣言的コードの可読性
sub demonstrate_readability {
    my @orders = (
        {
            id    => 'ORD001',
            items => [
                {name => 'Book',   price => 1000, quantity => 2, in_stock => 1},
                {name => 'Pen',    price => 200,  quantity => 5, in_stock => 1},
                {name => 'Eraser', price => 100,  quantity => 3, in_stock => 0},    # 在庫なし
            ],
        },
        {
            id    => 'ORD002',
            items => [{name => 'Notebook', price => 500, quantity => 1, in_stock => 1},],
        },
    );

    say "=== 命令的処理 ===";
    my $result_imp = process_items_imperative(\@orders);
    say "合計: " . $result_imp->{total};

    say "\n=== 宣言的処理 ===";
    my $result_dec = process_items_declarative(\@orders);
    say "合計: " . $result_dec->{total};

    return $result_dec;
}

1;

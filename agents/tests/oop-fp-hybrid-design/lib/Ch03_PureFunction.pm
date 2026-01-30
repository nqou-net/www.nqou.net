package Ch03_PureFunction;
use v5.36;
use Exporter 'import';
our @EXPORT_OK = qw(
    calculate_subtotal_impure
    calculate_subtotal_pure
    calculate_discount_pure
    calculate_total_pure
);

# 第3回: 純粋関数と副作用の分離
# 副作用（ログ、DB）を持つ関数 vs 純粋関数

# 問題版: 副作用が混在した計算メソッド
my @log_buffer;    # テスト用のログバッファ

sub calculate_subtotal_impure ($items, $db_connection, $logger) {

    # 副作用1: ログ出力
    push @log_buffer, "計算開始: " . scalar(@$items) . "件";

    my $subtotal = 0;
    for my $item (@$items) {
        $subtotal += $item->{price} * $item->{quantity};

        # 副作用2: DB更新（在庫チェック）
        # $db_connection->update_stock($item->{id}, $item->{quantity});
    }

    # 副作用3: 外部サービス呼び出し
    # $logger->info("Subtotal calculated: $subtotal");
    push @log_buffer, "計算完了: $subtotal";

    return $subtotal;
}

# 解決版: 純粋関数として抽出

sub calculate_subtotal_pure ($items) {

    # 入力: 商品リスト
    # 出力: 小計（数値）
    # 副作用: なし
    my $subtotal = 0;
    for my $item (@$items) {
        $subtotal += $item->{price} * $item->{quantity};
    }
    return $subtotal;
}

sub calculate_discount_pure ($subtotal, $discount_rate) {

    # 入力: 小計、割引率
    # 出力: 割引額
    # 副作用: なし
    return $subtotal * ($discount_rate / 100);
}

sub calculate_total_pure ($subtotal, $discount) {

    # 入力: 小計、割引額
    # 出力: 合計
    # 副作用: なし
    return $subtotal - $discount;
}

# 純粋関数の組み合わせ例
sub calculate_order_total ($items, $discount_rate) {
    my $subtotal = calculate_subtotal_pure($items);
    my $discount = calculate_discount_pure($subtotal, $discount_rate);
    my $total    = calculate_total_pure($subtotal, $discount);
    return $total;
}

# デモ: 純粋関数はテストが簡単
sub demonstrate_testability {
    my @items = ({name => 'Book', price => 1000, quantity => 2}, {name => 'Pen', price => 200, quantity => 5},);

    # 純粋関数は同じ入力に対して常に同じ出力
    my $subtotal = calculate_subtotal_pure(\@items);
    say "小計: $subtotal";    # 3000

    my $discount = calculate_discount_pure($subtotal, 10);
    say "割引額: $discount";    # 300

    my $total = calculate_total_pure($subtotal, $discount);
    say "合計: $total";        # 2700

    # モック不要、外部依存なし、高速
    return $total;
}

# テスト用ヘルパー
sub get_log_buffer   { return [@log_buffer]; }
sub clear_log_buffer { @log_buffer = (); }

1;

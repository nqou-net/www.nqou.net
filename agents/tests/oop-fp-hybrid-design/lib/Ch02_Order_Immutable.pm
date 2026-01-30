package Ch02_Order_Immutable;
use v5.36;
use Moo;

# 第2回: イミュータブルオブジェクト - is => 'ro' と with_* メソッド
# 状態を直接変更せず、新しいオブジェクトを返すパターン

has customer_name => (is => 'ro', required => 1);
has items         => (is => 'ro', default  => sub { [] });
has discount_rate => (is => 'ro', default  => 0);

# 計算結果はキャッシュせず、毎回計算（純粋な導出値）
sub total ($self) {
    my $subtotal = 0;
    for my $item ($self->items->@*) {
        $subtotal += $item->{price} * $item->{quantity};
    }
    return $subtotal * (1 - $self->discount_rate / 100);
}

# with_* パターン: 新しいオブジェクトを返す
sub with_item ($self, $item) {
    my @new_items = ($self->items->@*, $item);
    return Ch02_Order_Immutable->new(
        customer_name => $self->customer_name,
        items         => \@new_items,
        discount_rate => $self->discount_rate,
    );
}

sub with_discount ($self, $rate) {
    return Ch02_Order_Immutable->new(
        customer_name => $self->customer_name,
        items         => $self->items,
        discount_rate => $rate,
    );
}

# 複数の割引を合成する場合も新しいオブジェクトで対応
sub with_additional_discount ($self, $rate) {
    my $new_rate = $self->discount_rate + $rate;
    return $self->with_discount($new_rate);
}

# イミュータブルによる安全な処理のデモ
sub demonstrate_safety {
    my $order = Ch02_Order_Immutable->new(customer_name => 'Alice');

    my $order_with_item = $order->with_item({name => 'Book', price => 1000, quantity => 2});
    say "注文合計: " . $order_with_item->total;    # 2000

    # 各ハンドラは新しいオブジェクトを返す（元のオブジェクトは不変）
    my $apply_coupon = sub ($o) {
        return $o->with_additional_discount(10);    # クーポン適用
    };

    my $apply_member = sub ($o) {
        return $o->with_additional_discount(20);    # 会員割引
    };

    my $order_coupon = $apply_coupon->($order_with_item);
    say "クーポン後: " . $order_coupon->total;           # 1800

    my $order_both = $apply_member->($order_coupon);
    say "両方適用後: " . $order_both->total;             # 1400 (30%引き = 期待通り!)

    # 元のオブジェクトは変わっていない
    say "元の注文: " . $order_with_item->total;         # 2000 (不変!)

    return $order_both;
}

1;

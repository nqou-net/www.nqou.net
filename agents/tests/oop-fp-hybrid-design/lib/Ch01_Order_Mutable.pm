package Ch01_Order_Mutable;
use v5.36;
use Moo;

# 第1回: 可変状態の問題 - MutableなOrderクラス（バグあり）
# ECサイトの注文処理で、同じオブジェクトを複数箇所で変更すると状態が壊れる

has customer_name => (is => 'rw', required => 1);
has items         => (is => 'rw', default => sub { [] });
has discount_rate => (is => 'rw', default => 0);
has total         => (is => 'rw', default => 0);

sub add_item ($self, $item) {
    push $self->items->@*, $item;
    $self->_recalculate_total();
}

sub apply_discount ($self, $rate) {
    $self->discount_rate($rate);
    $self->_recalculate_total();
    
    # 問題: ログ出力など副作用がメソッド内に混在
    say "割引 $rate% を適用しました";
}

sub _recalculate_total ($self) {
    my $subtotal = 0;
    for my $item ($self->items->@*) {
        $subtotal += $item->{price} * $item->{quantity};
    }
    my $discount = $subtotal * ($self->discount_rate / 100);
    $self->total($subtotal - $discount);
}

# 問題を示すシナリオ: 複数箇所でオブジェクトを変更
sub demonstrate_bug {
    my $order = Ch01_Order_Mutable->new(customer_name => 'Alice');
    
    $order->add_item({ name => 'Book', price => 1000, quantity => 2 });
    say "注文合計: " . $order->total;  # 2000
    
    # ここで別の処理がdiscountを変更...
    my $coupon_handler = sub ($o) {
        $o->apply_discount(10);  # クーポン適用
    };
    
    # さらに別の処理が同じオブジェクトを変更...
    my $member_handler = sub ($o) {
        $o->apply_discount(20);  # 会員割引（クーポンを上書き！）
    };
    
    $coupon_handler->($order);
    say "クーポン後: " . $order->total;  # 1800 (期待通り)
    
    $member_handler->($order);
    say "会員割引後: " . $order->total;  # 1600 (クーポンが消えた！)
    
    # 本来は「クーポン10% + 会員割引20% = 30%」を期待していたが、
    # 可変状態への直接変更により、割引が上書きされてしまった
    
    return $order;
}

1;

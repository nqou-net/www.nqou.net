package Bar;
use v5.36;

sub new($class, %args) {
    return bless {
        name    => $args{name} // 'バー',
        waiter  => $args{waiter},
        kitchen => $args{kitchen},
        cashier => $args{cashier},
    }, $class;
}

sub name($self) { $self->{name} }

# ドリンクを準備する
sub prepare($self, $order) {
    my $item = $order->{item} // '不明なドリンク';
    my $result = "Bar: $item を準備中";

    # 会計に直接通知
    $self->{cashier}->add_to_bill($order);

    return $result;
}

# 提供完了をウェイターに直接通知
sub notify_ready($self, $order) {
    return "Bar -> Waiter: テーブル$order->{table}のドリンク完成";
}

1;

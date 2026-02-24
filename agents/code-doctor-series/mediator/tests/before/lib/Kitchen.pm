package Kitchen;
use v5.36;

sub new($class, %args) {
    return bless {
        name    => $args{name} // 'キッチン',
        waiter  => $args{waiter},
        bar     => $args{bar},
        cashier => $args{cashier},
        # デリバリー追加したら、ここも変更...
    }, $class;
}

sub name($self) { $self->{name} }

# 料理を準備する
sub prepare($self, $order) {
    my $item = $order->{item} // '不明な料理';
    my $result = "Kitchen: $item を調理中";

    # ドリンク付きなら直接バーに通知
    if ($order->{with_drink}) {
        $self->{bar}->prepare({
            type => 'drink',
            item => $order->{drink_item} // 'お水',
            table => $order->{table},
        });
    }

    return $result;
}

# 調理完了をウェイターに直接通知
sub notify_ready($self, $order) {
    # ウェイターを直接呼ぶ... 結合が深い
    return "Kitchen -> Waiter: テーブル$order->{table}の料理完成";
}

1;

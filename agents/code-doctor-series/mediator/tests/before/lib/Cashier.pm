package Cashier;
use v5.36;

sub new($class, %args) {
    return bless {
        name    => $args{name} // '会計',
        waiter  => $args{waiter},
        kitchen => $args{kitchen},
        bar     => $args{bar},
        bills   => {},
    }, $class;
}

sub name($self) { $self->{name} }

# 注文を伝票に追加
sub add_to_bill($self, $order) {
    my $table = $order->{table} // 'unknown';
    $self->{bills}{$table} //= [];
    push $self->{bills}{$table}->@*, $order->{item} // '不明';
    return "Cashier: テーブル${table}に追加";
}

# 会計（精算）
sub checkout($self, $table) {
    my $items = $self->{bills}{$table} // [];
    my $count = scalar $items->@*;
    delete $self->{bills}{$table};
    return "Cashier: テーブル${table} ${count}品のお会計完了";
}

1;

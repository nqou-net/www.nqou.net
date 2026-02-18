package OrderSystem;
use v5.36;
use Order;

sub new ($class) {
    return bless {orders => []}, $class;
}

sub add_order ($self, %args) {
    my $order = Order->new(%args);
    push $self->{orders}->@*, $order;
    return $order;
}

sub orders ($self) { $self->{orders}->@* }

sub total_by_table ($self, $table_no) {
    my $total = 0;
    for my $order ($self->{orders}->@*) {
        $total += $order->subtotal if $order->table_no == $table_no;
    }
    return $total;
}

# 価格改定……全注文を走査して書き換えるしかない
# これ絶対バグるけど他にやりようがない
sub update_price ($self, $menu_name, $new_price) {
    my $updated = 0;
    for my $order ($self->{orders}->@*) {
        if ($order->menu_item->name eq $menu_name) {
            $order->menu_item->{price} = $new_price;    # 直接書き換え……
            $updated++;
        }
    }
    return $updated;
}

# メモリ上にMenuItemオブジェクトが何個あるか数える
sub count_menu_objects ($self) {
    my %seen;
    for my $order ($self->{orders}->@*) {
        $seen{$order->menu_item + 0}++;    # リファレンスのアドレスで区別
    }
    return scalar keys %seen;
}

1;

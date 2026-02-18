package OrderSystem;
use v5.36;
use MenuItemPool;
use Order;

sub new ($class) {
    return bless {
        pool   => MenuItemPool->new,
        orders => [],
    }, $class;
}

sub pool ($self) { $self->{pool} }

sub add_order ($self, %args) {

    # メニュー情報はプールから取得（Flyweight）
    my $item = $self->{pool}->get(
        $args{menu_name},
        price    => $args{menu_price},
        calorie  => $args{menu_calorie},
        category => $args{menu_category},
        image    => $args{menu_image},
    );

    my $order = Order->new(
        menu_item => $item,
        table_no  => $args{table_no},
        quantity  => $args{quantity},
    );

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

# 価格改定はプールの1箇所だけ変更すれば全注文に反映
sub update_price ($self, $menu_name, $new_price) {
    $self->{pool}->update_price($menu_name, $new_price);
    return $self;
}

# メモリ上の MenuItem 数 = プールサイズのみ
sub count_menu_objects ($self) {
    return $self->{pool}->pool_size;
}

1;

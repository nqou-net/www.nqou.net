package Order;
use v5.36;
use MenuItem;

# 注文を作るたびにMenuItemを新しく生成する
# TODO: なんか金曜の夜に重くなるんだよな……
sub new ($class, %args) {

    # メニュー情報をまるごとコピーして注文オブジェクトに持たせる
    my $item = MenuItem->new(
        name     => $args{menu_name},
        price    => $args{menu_price},
        calorie  => $args{menu_calorie},
        category => $args{menu_category},
        image    => $args{menu_image},
    );

    return bless {
        menu_item  => $item,
        table_no   => $args{table_no},
        quantity   => $args{quantity},
        ordered_at => $args{ordered_at} // time(),
    }, $class;
}

sub menu_item  ($self) { $self->{menu_item} }
sub table_no   ($self) { $self->{table_no} }
sub quantity   ($self) { $self->{quantity} }
sub ordered_at ($self) { $self->{ordered_at} }

sub subtotal ($self) {
    return $self->{menu_item}->price * $self->{quantity};
}

sub to_string ($self) {
    return sprintf("テーブル%d: %s x%d = ¥%d", $self->{table_no}, $self->{menu_item}->name, $self->{quantity}, $self->subtotal,);
}

1;

package Order;
use v5.36;

# Extrinsic State のみ保持。MenuItem への参照は共有オブジェクト
sub new ($class, %args) {
    return bless {
        menu_item  => $args{menu_item},              # Flyweight への参照（共有）
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

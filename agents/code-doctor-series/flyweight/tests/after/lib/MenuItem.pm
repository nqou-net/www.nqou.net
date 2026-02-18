package MenuItem;
use v5.36;

# Flyweight オブジェクト — Intrinsic State のみ保持
# インスタンスは MenuItemPool 経由でのみ取得する
sub new ($class, %args) {
    return bless {
        name     => $args{name},
        price    => $args{price},
        calorie  => $args{calorie},
        category => $args{category},
        image    => $args{image} // 'no_image.png',
    }, $class;
}

sub name     ($self) { $self->{name} }
sub price    ($self) { $self->{price} }
sub calorie  ($self) { $self->{calorie} }
sub category ($self) { $self->{category} }
sub image    ($self) { $self->{image} }

sub set_price ($self, $new_price) {
    $self->{price} = $new_price;
    return $self;
}

sub to_string ($self) {
    return sprintf("%s (%s) ¥%d / %dkcal", $self->{name}, $self->{category}, $self->{price}, $self->{calorie});
}

1;

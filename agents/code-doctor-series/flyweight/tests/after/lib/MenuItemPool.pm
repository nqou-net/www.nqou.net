package MenuItemPool;
use v5.36;
use MenuItem;

# Flyweight Factory — メニューのマスター台帳
# 同一メニューは1つのオブジェクトだけ生成し、以降はキャッシュから返す
sub new ($class) {
    return bless {pool => {}}, $class;
}

sub get ($self, $name, %args) {
    unless (exists $self->{pool}{$name}) {
        $self->{pool}{$name} = MenuItem->new(name => $name, %args);
    }
    return $self->{pool}{$name};
}

sub update_price ($self, $name, $new_price) {
    die "メニュー '$name' はプールに存在しません" unless exists $self->{pool}{$name};
    $self->{pool}{$name}->set_price($new_price);
    return $self;
}

sub pool_size ($self) {
    return scalar keys $self->{pool}->%*;
}

sub has ($self, $name) {
    return exists $self->{pool}{$name};
}

1;

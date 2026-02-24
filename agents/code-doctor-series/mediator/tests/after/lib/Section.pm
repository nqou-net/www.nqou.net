package Section;
use v5.36;

# 全セクション共通の基底クラス
sub new($class, %args) {
    return bless {
        name     => $args{name} // '不明',
        mediator => undef,
    }, $class;
}

sub name($self) { $self->{name} }

sub set_mediator($self, $mediator) {
    $self->{mediator} = $mediator;
}

sub mediator($self) { $self->{mediator} }

1;

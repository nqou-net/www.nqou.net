package ClothCraft::Expression::Literal;
use v5.36;
use parent 'ClothCraft::Expression';

# 終端式: リテラル値（数値・文字列）

sub new ($class, $value) {
    return $class->SUPER::new(value => $value);
}

sub interpret ($self, $context) {
    return $self->{value};
}

1;

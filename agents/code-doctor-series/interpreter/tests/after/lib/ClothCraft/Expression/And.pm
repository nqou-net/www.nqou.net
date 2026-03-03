package ClothCraft::Expression::And;
use v5.36;
use parent 'ClothCraft::Expression';

# 非終端式: 論理AND

sub new ($class, $left, $right) {
    return $class->SUPER::new(left => $left, right => $right);
}

sub interpret ($self, $context) {
    return $self->{left}->interpret($context) && $self->{right}->interpret($context);
}

1;

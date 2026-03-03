package ClothCraft::Expression::Not;
use v5.36;
use parent 'ClothCraft::Expression';

# 非終端式: 論理NOT

sub new ($class, $expr) {
    return $class->SUPER::new(expr => $expr);
}

sub interpret ($self, $context) {
    return !$self->{expr}->interpret($context);
}

1;

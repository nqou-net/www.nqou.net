package ClothCraft::Expression::Comparison;
use v5.36;
use parent 'ClothCraft::Expression';
use Carp qw(croak);

# 終端式: 比較演算（>=, <=, ==, !=, eq, ne）

my %OPS = (
    '>='  => sub ($a, $b) { $a >= $b },
    '<='  => sub ($a, $b) { $a <= $b },
    '>'   => sub ($a, $b) { $a > $b },
    '<'   => sub ($a, $b) { $a < $b },
    '=='  => sub ($a, $b) { $a == $b },
    '!='  => sub ($a, $b) { $a != $b },
    'eq'  => sub ($a, $b) { $a eq $b },
    'ne'  => sub ($a, $b) { $a ne $b },
);

sub new ($class, $left, $op, $right) {
    croak "Unknown operator: $op" unless exists $OPS{$op};
    return $class->SUPER::new(left => $left, op => $op, right => $right);
}

sub interpret ($self, $context) {
    my $left_val  = $self->{left}->interpret($context);
    my $right_val = $self->{right}->interpret($context);
    return $OPS{$self->{op}}->($left_val, $right_val);
}

1;

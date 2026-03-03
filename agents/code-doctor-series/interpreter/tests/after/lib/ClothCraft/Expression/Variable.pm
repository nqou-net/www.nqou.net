package ClothCraft::Expression::Variable;
use v5.36;
use parent 'ClothCraft::Expression';
use Carp qw(croak);

# 終端式: コンテキスト変数の参照

sub new ($class, $name) {
    return $class->SUPER::new(name => $name);
}

sub interpret ($self, $context) {
    my $name = $self->{name};
    croak "Unknown variable: $name" unless exists $context->{$name};
    return $context->{$name};
}

1;

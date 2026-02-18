package Ingredient;
use v5.36;
use parent 'RecipeComponent';

sub new ($class, %args) {
    my $self = $class->SUPER::new(%args);
    $self->{quantity} = $args{quantity} // 0;
    $self->{unit}     = $args{unit}     // 'g';
    return $self;
}

sub quantity ($self) { $self->{quantity} }
sub unit     ($self) { $self->{unit} }

# Leaf: 自分自身の量を返す
sub calculate ($self) {
    return {$self->name => {quantity => $self->{quantity}, unit => $self->{unit}}};
}

# Leaf: 自分を表示
sub display ($self, $indent = 0) {
    my $prefix = '  ' x $indent;
    say "${prefix}${\$self->name}: $self->{quantity}$self->{unit}";
}

1;

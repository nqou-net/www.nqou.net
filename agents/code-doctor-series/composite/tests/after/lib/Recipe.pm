package Recipe;
use v5.36;
use parent 'RecipeComponent';

sub new ($class, %args) {
    my $self = $class->SUPER::new(%args);
    $self->{children} = [];
    return $self;
}

# 子要素の追加（Ingredient でも Recipe でも同じ）
sub add ($self, $child) {
    push $self->{children}->@*, $child;
    return $self;    # メソッドチェーン用
}

# Composite: 子要素の合計を再帰的に集計
sub calculate ($self) {
    my %totals;
    for my $child ($self->{children}->@*) {
        my $child_totals = $child->calculate;
        for my $name (keys %$child_totals) {
            $totals{$name} //= {quantity => 0, unit => $child_totals->{$name}{unit}};
            $totals{$name}{quantity} += $child_totals->{$name}{quantity};
        }
    }
    return \%totals;
}

# Composite: ツリー表示
sub display ($self, $indent = 0) {
    my $prefix = '  ' x $indent;
    say "${prefix}[${\$self->name}]";
    for my $child ($self->{children}->@*) {
        $child->display($indent + 1);
    }
}

1;

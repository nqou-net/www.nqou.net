#!/usr/bin/env perl
use v5.36;

package ExpressionRole {
    use Moo::Role;
    requires 'eval';
}

package NumberExpr {
    use Moo;
    with 'ExpressionRole';
    has value => (is => 'ro', required => 1);
    sub eval($self) { return $self->value; }
}

package DiceExpr {
    use Moo;
    with 'ExpressionRole';
    has count => (is => 'ro', required => 1);
    has sides => (is => 'ro', required => 1);
    sub eval($self) {
        my $total = 0;
        for (1 .. $self->count) {
            $total += int(rand($self->sides)) + 1;
        }
        return $total;
    }
}

package AddExpr {
    use Moo;
    with 'ExpressionRole';
    has left  => (is => 'ro', required => 1);
    has right => (is => 'ro', required => 1);
    sub eval($self) { return $self->left->eval + $self->right->eval; }
}

package SubExpr {
    use Moo;
    with 'ExpressionRole';
    has left  => (is => 'ro', required => 1);
    has right => (is => 'ro', required => 1);
    sub eval($self) { return $self->left->eval - $self->right->eval; }
}

package MulExpr {
    use Moo;
    with 'ExpressionRole';
    has left  => (is => 'ro', required => 1);
    has right => (is => 'ro', required => 1);
    sub eval($self) { return $self->left->eval * $self->right->eval; }
}

# (2d6-1)*2
my $expr = MulExpr->new(
    left => SubExpr->new(
        left  => DiceExpr->new(count => 2, sides => 6),
        right => NumberExpr->new(value => 1),
    ),
    right => NumberExpr->new(value => 2),
);
say "(2d6-1)*2: " . $expr->eval;

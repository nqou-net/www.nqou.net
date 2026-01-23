#!/usr/bin/env perl
use v5.36;

package NumberExpr {
    use Moo;
    has value => (is => 'ro', required => 1);
    sub eval($self) { return $self->value; }
}

package DiceExpr {
    use Moo;
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
    has left  => (is => 'ro', required => 1);
    has right => (is => 'ro', required => 1);
    sub eval($self) {
        return $self->left->eval + $self->right->eval;
    }
}

# 2d6+3 を組み立てる
my $expr = AddExpr->new(
    left  => DiceExpr->new(count => 2, sides => 6),
    right => NumberExpr->new(value => 3),
);

say "2d6+3の結果: " . $expr->eval;

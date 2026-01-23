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

package DiceParser {
    use Moo;

    sub parse($self, $input) {
        $input =~ s/\s+//g;
        return $self->_parse_additive($input);
    }

    sub _parse_additive($self, $input) {
        if ($input =~ /^(.+)([\+\-])([^\+\-]+)$/) {
            my ($left, $op, $right) = ($1, $2, $3);
            my $left_expr  = $self->_parse_additive($left);
            my $right_expr = $self->_parse_multiplicative($right);
            return $op eq '+'
                ? AddExpr->new(left => $left_expr, right => $right_expr)
                : SubExpr->new(left => $left_expr, right => $right_expr);
        }
        return $self->_parse_multiplicative($input);
    }

    sub _parse_multiplicative($self, $input) {
        if ($input =~ /^(.+)\*([^\*]+)$/) {
            my ($left, $right) = ($1, $2);
            return MulExpr->new(
                left  => $self->_parse_multiplicative($left),
                right => $self->_parse_primary($right),
            );
        }
        return $self->_parse_primary($input);
    }

    sub _parse_primary($self, $input) {
        return DiceExpr->new(count => $1, sides => $2) if $input =~ /^(\d+)d(\d+)$/;
        return NumberExpr->new(value => $1) if $input =~ /^(\d+)$/;
        die "パースエラー: $input";
    }
}

# ダイス言語インタプリタを使う
my $parser = DiceParser->new;

my @expressions = ('2d6', '2d6+3', '3d8-5', '1d20*2', '2d6+3*2');

for my $input (@expressions) {
    my $expr   = $parser->parse($input);
    my $result = $expr->eval;
    say "$input = $result";
}

#!/usr/bin/env perl
use v5.36;

package NumberExpr {
    use Moo;

    has value => (is => 'ro', required => 1);

    sub eval($self) {
        return $self->value;
    }
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

# 使ってみる
my $num = NumberExpr->new(value => 5);
say "数値5: " . $num->eval;

my $dice = DiceExpr->new(count => 2, sides => 6);
say "2d6: " . $dice->eval;

my $dice20 = DiceExpr->new(count => 1, sides => 20);
say "1d20: " . $dice20->eval;

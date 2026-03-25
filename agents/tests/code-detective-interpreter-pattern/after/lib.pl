use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

# === After: Interpreter Pattern ===
# ビジネスルールを Expression オブジェクトの木構造として表現する。
# 終端記号（Terminal）は単一条件、非終端記号（Non-terminal）は論理演算。
# 新しいルールは既存コードの改修なしに、Expression の組み合わせで追加できる。

package Order {
    use Moo;
    use Types::Standard qw(Num Bool Int);

    has total      => (is => 'ro', isa => Num,  required => 1);
    has is_member  => (is => 'ro', isa => Bool, default  => 0);
    has item_count => (is => 'ro', isa => Int,  default  => 1);
}

# --- 抽象基底（Role） ---
package Expression {
    use Moo::Role;
    requires 'evaluate';
}

# --- Terminal Expressions（終端記号） ---
package AmountOver {
    use Moo;
    use Types::Standard qw(Num);
    with 'Expression';

    has threshold => (is => 'ro', isa => Num, required => 1);

    sub evaluate ($self, $order) {
        return $order->total >= $self->threshold;
    }
}

package IsMember {
    use Moo;
    with 'Expression';

    sub evaluate ($self, $order) {
        return $order->is_member;
    }
}

package ItemCountOver {
    use Moo;
    use Types::Standard qw(Int);
    with 'Expression';

    has threshold => (is => 'ro', isa => Int, required => 1);

    sub evaluate ($self, $order) {
        return $order->item_count >= $self->threshold;
    }
}

# --- Non-terminal Expressions（非終端記号） ---
package AndExpr {
    use Moo;
    with 'Expression';

    has left  => (is => 'ro', required => 1);
    has right => (is => 'ro', required => 1);

    sub evaluate ($self, $order) {
        return $self->left->evaluate($order) && $self->right->evaluate($order);
    }
}

package OrExpr {
    use Moo;
    with 'Expression';

    has left  => (is => 'ro', required => 1);
    has right => (is => 'ro', required => 1);

    sub evaluate ($self, $order) {
        return $self->left->evaluate($order) || $self->right->evaluate($order);
    }
}

# --- ルール定義 ---
package DiscountRule {
    use Moo;
    use Types::Standard qw(Num);

    has expression => (is => 'ro', required => 1);
    has rate       => (is => 'ro', isa => Num, required => 1);

    sub matches ($self, $order) {
        return $self->expression->evaluate($order);
    }
}

# --- ルールエンジン ---
package RuleEngine {
    use Moo;
    use Types::Standard qw(ArrayRef);

    has rules => (is => 'ro', isa => ArrayRef, required => 1);

    sub calculate ($self, $order) {
        for my $rule (@{ $self->rules }) {
            return $rule->rate if $rule->matches($order);
        }
        return 0;
    }
}

1;

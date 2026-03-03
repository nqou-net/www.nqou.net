package ClothCraft::CouponEngine;
use v5.36;
use Carp qw(croak);
use ClothCraft::RuleParser;

# Interpreter パターン適用後のクーポンエンジン
# eval を完全に排除し、Expression ツリーで安全にルールを評価する

sub new ($class) {
    my $parser = ClothCraft::RuleParser->new;
    return bless {
        rules  => [],
        parser => $parser,
    }, $class;
}

sub add_rule ($self, %rule) {
    my $expr = $self->{parser}->parse($rule{condition});
    push $self->{rules}->@*, {
        name     => $rule{name},
        expr     => $expr,
        discount => $rule{discount},
    };
    return $self;
}

sub evaluate ($self, $context) {
    my @applicable;
    for my $rule ($self->{rules}->@*) {
        if ($rule->{expr}->interpret($context)) {
            push @applicable, {
                name     => $rule->{name},
                discount => $rule->{discount},
            };
        }
    }
    return \@applicable;
}

sub best_discount ($self, $context) {
    my $applicable = $self->evaluate($context);
    return undef unless $applicable->@*;

    my @sorted = sort { $b->{discount} <=> $a->{discount} } $applicable->@*;
    return $sorted[0];
}

1;

use v5.36;
use Test::More;
use List::Util qw(reduce sum0);    # map/grep are builtins

my $items = [
    {name => 'Widget A', price => 1000, category => 'elect'},
    {name => 'Widget B', price => 2000, category => 'book'},
    {name => 'Widget C', price => 1500, category => 'elect'},
];

subtest 'Imperative (Loop) Style' => sub {
    my $total = 0;
    for my $item ($items->@*) {
        if ($item->{category} eq 'elect') {
            $total += $item->{price};
        }
    }
    is $total, 2500, 'Loop calculation correct';
};

subtest 'Declarative (FP) Style' => sub {

    # "What to do" instead of "How to do"
    my $total = sum0(
        map  { $_->{price} }
        grep { $_->{category} eq 'elect' } $items->@*
    );

    is $total, 2500, 'Declarative calculation correct';
};

subtest 'Complex Transformation' => sub {

    # Pipeline: Filter -> Transform -> Reduce
    my $result = reduce { $a + $b }
        map  { $_->{price} * 1.1 }      # Add tax
        grep { $_->{price} >= 1500 }    # Filter high value
        $items->@*;

    # Widget B (2000) + Widget C (1500) -> Taxed: 2200 + 1650 = 3850
    is $result, 3850, 'Pipeline calculation correct';
};

done_testing;

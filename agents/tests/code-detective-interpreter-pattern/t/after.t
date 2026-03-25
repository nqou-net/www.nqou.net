use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use Test::More;

do './agents/tests/code-detective-interpreter-pattern/after/lib.pl' or die $@ || $!;

# --- Beforeと同等の4ルールを Expression の組み合わせで構築 ---
my $engine = RuleEngine->new(
    rules => [
        # 会員かつ1万円以上 → 15%
        DiscountRule->new(
            expression => AndExpr->new(
                left  => AmountOver->new(threshold => 10000),
                right => IsMember->new,
            ),
            rate => 0.15,
        ),
        # 1万円以上（非会員含む） → 10%
        DiscountRule->new(
            expression => AmountOver->new(threshold => 10000),
            rate       => 0.10,
        ),
        # 会員かつ5点以上 → 8%
        DiscountRule->new(
            expression => AndExpr->new(
                left  => IsMember->new,
                right => ItemCountOver->new(threshold => 5),
            ),
            rate => 0.08,
        ),
        # 3点以上 → 5%
        DiscountRule->new(
            expression => ItemCountOver->new(threshold => 3),
            rate       => 0.05,
        ),
    ],
);

subtest 'After: 会員かつ1万円以上 → 15%' => sub {
    my $order = Order->new(total => 15000, is_member => 1, item_count => 2);
    is($engine->calculate($order), 0.15, '会員+高額で最大割引');
};

subtest 'After: 非会員で1万円以上 → 10%' => sub {
    my $order = Order->new(total => 10000, is_member => 0, item_count => 1);
    is($engine->calculate($order), 0.10, '非会員でも高額なら10%');
};

subtest 'After: 会員かつ5点以上 → 8%' => sub {
    my $order = Order->new(total => 3000, is_member => 1, item_count => 5);
    is($engine->calculate($order), 0.08, '会員+まとめ買いで8%');
};

subtest 'After: 3点以上 → 5%' => sub {
    my $order = Order->new(total => 2000, is_member => 0, item_count => 3);
    is($engine->calculate($order), 0.05, '非会員でも3点以上で5%');
};

subtest 'After: 条件に合致しない → 0%' => sub {
    my $order = Order->new(total => 1000, is_member => 0, item_count => 1);
    is($engine->calculate($order), 0, '割引なし');
};

subtest 'After: FIX — 新ルールを既存コード改修なしに追加できる' => sub {
    # 「会員かつ3点以上かつ5000円以上で12%」を先頭に追加
    my $extended = RuleEngine->new(
        rules => [
            DiscountRule->new(
                expression => AndExpr->new(
                    left => IsMember->new,
                    right => AndExpr->new(
                        left  => ItemCountOver->new(threshold => 3),
                        right => AmountOver->new(threshold => 5000),
                    ),
                ),
                rate => 0.12,
            ),
            @{ $engine->rules },
        ],
    );

    my $order = Order->new(total => 6000, is_member => 1, item_count => 4);
    is($extended->calculate($order), 0.12, 'FIX: 新ルールが適用される');

    # 既存ルールも壊れていない
    my $old_order = Order->new(total => 15000, is_member => 1, item_count => 2);
    is($extended->calculate($old_order), 0.15, 'FIX: 既存ルールも正常');
};

subtest 'After: FIX — OrExpr で OR 条件を表現できる' => sub {
    # 「会員または1万円以上で10%」
    my $or_engine = RuleEngine->new(
        rules => [
            DiscountRule->new(
                expression => OrExpr->new(
                    left  => IsMember->new,
                    right => AmountOver->new(threshold => 10000),
                ),
                rate => 0.10,
            ),
        ],
    );

    my $member  = Order->new(total => 500,   is_member => 1, item_count => 1);
    my $big     = Order->new(total => 12000, is_member => 0, item_count => 1);
    my $neither = Order->new(total => 500,   is_member => 0, item_count => 1);

    is($or_engine->calculate($member),  0.10, '会員なら適用');
    is($or_engine->calculate($big),     0.10, '高額なら適用');
    is($or_engine->calculate($neither), 0,    'どちらでもなければ不適用');
};

subtest 'After: FIX — Expression を does で確認できる' => sub {
    ok(AmountOver->new(threshold => 1000)->does('Expression'),  'AmountOver は Expression');
    ok(IsMember->new->does('Expression'),                       'IsMember は Expression');
    ok(ItemCountOver->new(threshold => 3)->does('Expression'),  'ItemCountOver は Expression');
    ok(AndExpr->new(left => IsMember->new, right => IsMember->new)->does('Expression'),
       'AndExpr は Expression');
    ok(OrExpr->new(left => IsMember->new, right => IsMember->new)->does('Expression'),
       'OrExpr は Expression');
};

done_testing;

use v5.36;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

use ClothCraft::CouponEngine;
use ClothCraft::RuleParser;

# --- パーサー単体テスト ---
{
    my $parser = ClothCraft::RuleParser->new;

    # 単純な比較
    my $expr = $parser->parse('cart_total >= 5000');
    ok($expr->interpret({ cart_total => 8000 }), '8000 >= 5000 は真');
    ok(!$expr->interpret({ cart_total => 3000 }), '3000 >= 5000 は偽');

    # 文字列比較
    my $eq_expr = $parser->parse('member_rank eq "gold"');
    ok($eq_expr->interpret({ member_rank => 'gold' }), 'gold eq gold は真');
    ok(!$eq_expr->interpret({ member_rank => 'normal' }), 'normal eq gold は偽');

    # AND
    my $and_expr = $parser->parse('cart_total >= 5000 AND member_rank eq "gold"');
    ok($and_expr->interpret({ cart_total => 8000, member_rank => 'gold' }), 'AND: 両方真');
    ok(!$and_expr->interpret({ cart_total => 8000, member_rank => 'normal' }), 'AND: 片方偽');

    # OR
    my $or_expr = $parser->parse('is_first_purchase == 1 OR member_rank eq "platinum"');
    ok($or_expr->interpret({ is_first_purchase => 1, member_rank => 'normal' }), 'OR: 左が真');
    ok($or_expr->interpret({ is_first_purchase => 0, member_rank => 'platinum' }), 'OR: 右が真');
    ok(!$or_expr->interpret({ is_first_purchase => 0, member_rank => 'normal' }), 'OR: 両方偽');

    # NOT
    my $not_expr = $parser->parse('NOT is_first_purchase == 1');
    ok($not_expr->interpret({ is_first_purchase => 0 }), 'NOT: 偽の否定は真');
    ok(!$not_expr->interpret({ is_first_purchase => 1 }), 'NOT: 真の否定は偽');

    # 括弧
    my $paren_expr = $parser->parse('cart_total >= 5000 AND (member_rank eq "gold" OR is_first_purchase == 1)');
    ok($paren_expr->interpret({ cart_total => 8000, member_rank => 'normal', is_first_purchase => 1 }),
       '括弧: AND + OR の複合式');
    ok(!$paren_expr->interpret({ cart_total => 3000, member_rank => 'gold', is_first_purchase => 0 }),
       '括弧: cart_total条件を満たさない');
}

# --- 不正な式のパースエラー ---
{
    my $parser = ClothCraft::RuleParser->new;

    eval { $parser->parse('cart_total >=== BROKEN') };
    ok($@, '不正な式はパース時にエラーになる');

    eval { $parser->parse('') };
    ok($@, '空文字列はエラーになる');
}

# --- CouponEngine統合テスト ---
my $engine = ClothCraft::CouponEngine->new;

$engine->add_rule(
    name      => 'ゴールド会員5000円以上',
    condition => 'cart_total >= 5000 AND member_rank eq "gold"',
    discount  => 500,
);

$engine->add_rule(
    name      => '初回購入割引',
    condition => 'is_first_purchase == 1',
    discount  => 300,
);

$engine->add_rule(
    name      => 'プラチナ会員1万円以上',
    condition => 'cart_total >= 10000 AND member_rank eq "platinum"',
    discount  => 1000,
);

# ゴールド会員
{
    my $context = {
        cart_total        => 8000,
        member_rank       => 'gold',
        is_first_purchase => 0,
    };
    my $result = $engine->evaluate($context);
    is(scalar @$result, 1, 'ゴールド会員8000円で1ルール適用');
    is($result->[0]{name}, 'ゴールド会員5000円以上', '正しいルールが適用');
    is($result->[0]{discount}, 500, '割引額500円');
}

# 初回購入
{
    my $context = {
        cart_total        => 2000,
        member_rank       => 'normal',
        is_first_purchase => 1,
    };
    my $result = $engine->evaluate($context);
    is(scalar @$result, 1, '初回購入で1ルール適用');
    is($result->[0]{name}, '初回購入割引', '初回購入割引が適用');
}

# best_discount
{
    my $context = {
        cart_total        => 12000,
        member_rank       => 'gold',
        is_first_purchase => 1,
    };
    my $best = $engine->best_discount($context);
    is($best->{name}, 'ゴールド会員5000円以上', 'ゴールド5000円以上が適用');
    is($best->{discount}, 500, '最大割引は500円');
}

# 条件不一致
{
    my $context = {
        cart_total        => 3000,
        member_rank       => 'normal',
        is_first_purchase => 0,
    };
    my $result = $engine->evaluate($context);
    is(scalar @$result, 0, '条件不一致で0件');
}

# --- 不正なルールはadd_rule時にエラー（evalと違い登録時に検出） ---
{
    my $bad_engine = ClothCraft::CouponEngine->new;
    eval {
        $bad_engine->add_rule(
            name      => '壊れたルール',
            condition => 'cart_total >=== BROKEN',
            discount  => 100,
        );
    };
    ok($@, '不正なルールは登録時にエラーになる（evalのように黙って飲み込まない）');
}

# --- 拡張性: 新しい複合条件も簡単に表現 ---
{
    my $ext_engine = ClothCraft::CouponEngine->new;
    $ext_engine->add_rule(
        name      => '複合条件ルール',
        condition => '(cart_total >= 3000 AND member_rank eq "gold") OR is_first_purchase == 1',
        discount  => 400,
    );

    ok($ext_engine->evaluate({ cart_total => 5000, member_rank => 'gold', is_first_purchase => 0 })->[0],
       '複合条件: ゴールド3000円以上で適用');
    ok($ext_engine->evaluate({ cart_total => 1000, member_rank => 'normal', is_first_purchase => 1 })->[0],
       '複合条件: 初回購入で適用');
    is(scalar $ext_engine->evaluate({ cart_total => 1000, member_rank => 'normal', is_first_purchase => 0 })->@*, 0,
       '複合条件: どちらも満たさず不適用');
}

done_testing;

use v5.36;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

use ClothCraft::CouponEngine;

my $engine = ClothCraft::CouponEngine->new;

# --- ルール登録（管理画面から入力される想定の文字列） ---
$engine->add_rule(
    name      => 'ゴールド会員5000円以上',
    condition => 'cart_total >= 5000 && member_rank eq "gold"',
    discount  => 500,
);

$engine->add_rule(
    name      => '初回購入割引',
    condition => 'is_first_purchase == 1',
    discount  => 300,
);

$engine->add_rule(
    name      => 'プラチナ会員1万円以上',
    condition => 'cart_total >= 10000 && member_rank eq "platinum"',
    discount  => 1000,
);

# --- 基本テスト: ゴールド会員 ---
{
    my $context = {
        cart_total        => 8000,
        member_rank       => 'gold',
        is_first_purchase => 0,
    };
    my $result = $engine->evaluate($context);
    is(scalar @$result, 1, 'ゴールド会員8000円で1ルールが適用');
    is($result->[0]{name}, 'ゴールド会員5000円以上', '正しいルールが適用');
    is($result->[0]{discount}, 500, '割引額500円');
}

# --- 初回購入 ---
{
    my $context = {
        cart_total        => 2000,
        member_rank       => 'normal',
        is_first_purchase => 1,
    };
    my $result = $engine->evaluate($context);
    is(scalar @$result, 1, '初回購入で1ルールが適用');
    is($result->[0]{name}, '初回購入割引', '初回購入割引が適用');
}

# --- 複数ルール適用 → best_discount ---
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

# --- 条件不一致 ---
{
    my $context = {
        cart_total        => 3000,
        member_rank       => 'normal',
        is_first_purchase => 0,
    };
    my $result = $engine->evaluate($context);
    is(scalar @$result, 0, '条件不一致で0件');
}

# --- 問題点: 不正なルール文字列はエラーが握りつぶされるだけ ---
{
    my $bad_engine = ClothCraft::CouponEngine->new;
    $bad_engine->add_rule(
        name      => '壊れたルール',
        condition => 'cart_total >=== BROKEN',  # 不正な式
        discount  => 100,
    );
    my $context = { cart_total => 5000, member_rank => 'gold', is_first_purchase => 0 };
    my $result = $bad_engine->evaluate($context);
    # evalエラーは黙って無視される... 桐山は「条件不一致」だと思っている
    is(scalar @$result, 0, '不正な式はエラーなく無視される（これが問題）');
}

done_testing;

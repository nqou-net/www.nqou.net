use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use Test::More;

do './agents/tests/code-detective-specification-pattern/before/lib.pl' or die $@ || $!;

subtest 'Before: ゴールド会員の割引（10%）' => sub {
    my $order = Order->new(member_rank => 'gold', total => 10000);
    my $svc   = DiscountService->new;

    is($svc->calculate_discount($order), 1000, 'ゴールド会員は10%割引');
};

subtest 'Before: シルバー会員の割引（5%）' => sub {
    my $order = Order->new(member_rank => 'silver', total => 10000);
    my $svc   = DiscountService->new;

    is($svc->calculate_discount($order), 500, 'シルバー会員は5%割引');
};

subtest 'Before: 一般会員は割引なし' => sub {
    my $order = Order->new(member_rank => 'normal', total => 10000);
    my $svc   = DiscountService->new;

    is($svc->calculate_discount($order), 0, '一般会員は割引なし');
};

subtest 'Before: キャンペーン × 5000円以上で500円割引' => sub {
    my $order = Order->new(
        member_rank        => 'normal',
        total              => 5000,
        is_campaign_period => 1,
    );
    my $svc = DiscountService->new;

    is($svc->calculate_discount($order), 500, 'キャンペーン割引が適用される');
};

subtest 'Before: キャンペーン × 5000円未満は割引なし' => sub {
    my $order = Order->new(
        member_rank        => 'normal',
        total              => 4999,
        is_campaign_period => 1,
    );
    my $svc = DiscountService->new;

    is($svc->calculate_discount($order), 0, '5000円未満はキャンペーン割引なし');
};

subtest 'Before: ゴールド × キャンペーン × 1万円以上の組み合わせ割引' => sub {
    my $order = Order->new(
        member_rank        => 'gold',
        total              => 10000,
        is_campaign_period => 1,
    );
    my $svc = DiscountService->new;

    # ゴールド10%(1000) + キャンペーン(500) + 組み合わせ(1000) = 2500
    is($svc->calculate_discount($order), 2500, '全条件の組み合わせで2500円割引');
};

subtest 'Before: 送料無料 — ゴールド会員' => sub {
    my $order = Order->new(member_rank => 'gold', total => 1000);
    my $svc   = DiscountService->new;

    ok($svc->is_free_shipping($order), 'ゴールド会員は送料無料');
};

subtest 'Before: 送料無料 — 5000円以上' => sub {
    my $order = Order->new(member_rank => 'normal', total => 5000);
    my $svc   = DiscountService->new;

    ok($svc->is_free_shipping($order), '5000円以上は送料無料');
};

subtest 'Before: 送料有料 — 一般会員 × 5000円未満' => sub {
    my $order = Order->new(member_rank => 'normal', total => 4999);
    my $svc   = DiscountService->new;

    ok(!$svc->is_free_shipping($order), '条件未達は送料有料');
};

subtest 'Before: ポイント計算 — ゴールド会員キャンペーン中' => sub {
    my $order = Order->new(
        member_rank        => 'gold',
        total              => 10000,
        is_campaign_period => 1,
    );
    my $svc = DiscountService->new;

    # 10000 * 0.01 = 100 → ゴールド2倍 = 200 → キャンペーン+100 = 300
    is($svc->calculate_points($order), 300, 'ゴールド × キャンペーンで300ポイント');
};

subtest 'Before: ポイント計算 — 一般会員キャンペーンなし' => sub {
    my $order = Order->new(member_rank => 'normal', total => 10000);
    my $svc   = DiscountService->new;

    is($svc->calculate_points($order), 100, '一般会員は1%の100ポイント');
};

done_testing;

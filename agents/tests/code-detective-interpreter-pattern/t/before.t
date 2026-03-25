use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use Test::More;

do './agents/tests/code-detective-interpreter-pattern/before/lib.pl' or die $@ || $!;

my $calc = DiscountCalculator->new;

subtest 'Before: 会員かつ1万円以上 → 15%' => sub {
    my $order = Order->new(total => 15000, is_member => 1, item_count => 2);
    is($calc->calculate($order), 0.15, '会員+高額で最大割引');
};

subtest 'Before: 非会員で1万円以上 → 10%' => sub {
    my $order = Order->new(total => 10000, is_member => 0, item_count => 1);
    is($calc->calculate($order), 0.10, '非会員でも高額なら10%');
};

subtest 'Before: 会員かつ5点以上 → 8%' => sub {
    my $order = Order->new(total => 3000, is_member => 1, item_count => 5);
    is($calc->calculate($order), 0.08, '会員+まとめ買いで8%');
};

subtest 'Before: 3点以上 → 5%' => sub {
    my $order = Order->new(total => 2000, is_member => 0, item_count => 3);
    is($calc->calculate($order), 0.05, '非会員でも3点以上で5%');
};

subtest 'Before: 条件に合致しない → 0%' => sub {
    my $order = Order->new(total => 1000, is_member => 0, item_count => 1);
    is($calc->calculate($order), 0, '割引なし');
};

subtest 'Before: PROBLEM — 新ルール追加には calculate メソッドの改修が必要' => sub {
    # 「会員かつ3点以上かつ5000円以上で12%」を追加したい場合、
    # calculate メソッド内部の if/elsif チェーンを直接書き換える必要がある。
    # 外部からルールを追加する手段がない。
    ok(!$calc->can('add_rule'), 'PROBLEM: add_rule() メソッドが存在しない');
};

done_testing;

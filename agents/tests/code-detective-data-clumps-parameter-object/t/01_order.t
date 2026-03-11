use strict;
use warnings;
use Test::More;

use lib 'lib';
use Before::OrderService;
use After::OrderContext;
use After::OrderService;

subtest 'Before - バケツリレーと引数順番間違いの悲劇' => sub {
    my $service = Before::OrderService->new;

    # user_id = 1 (プレミアムユーザー), shop_id = 99
    # 本来ならプレミアム割引の10% (100) が適用されて 900 になるはず
    # しかし、内部で引数の順番（user_idとshop_id）が入れ替わっているため、
    # calculate_discount では $user_id が 99 として処理され、プレミアム割引が適用されない
    my $amount = $service->process_order(
        1,       # user_id
        99,      # shop_id
        1001,    # item_id
        1000,    # amount
        undef,   # campaign_code
        'secret_token', # auth_token
    );

    # 悲劇の発生（意図した金額にならない）
    is $amount, 1000, 'Before: 引数間違いのせいで割引が適用されず、そのままの金額になる';
};

subtest 'After - Parameter Objectの導入' => sub {
    my $service = After::OrderService->new;

    my $context = After::OrderContext->new(
        user_id       => 1,      # 名前付き引数なので間違えようがない
        shop_id       => 99,
        item_id       => 1001,
        amount        => 1000,
        auth_token    => 'secret_token',
    );

    # 引数リストが1つだけになる
    my $amount = $service->process_order($context);

    # 期待通り、プレミアム割引10% (100) が適用されて 900 になる
    is $amount, 900, 'After: 順番間違いが起きず、正しく計算される';
};

subtest 'After - キャンペーンコードあり' => sub {
    my $service = After::OrderService->new;

    my $context = After::OrderContext->new(
        user_id       => 1,
        shop_id       => 99,
        item_id       => 1001,
        amount        => 1000,
        auth_token    => 'secret_token',
        campaign_code => 'SUMMER', # Contextの中身を増やすだけで済む
    );

    my $amount = $service->process_order($context);

    # プレミアム割引 (100) + サマーキャンペーン (500) = 600引かれて 400
    is $amount, 400, 'After: 要素が増えても安全に処理される';
};

done_testing;

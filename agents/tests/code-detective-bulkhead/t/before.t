use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use Test::More;

do './agents/tests/code-detective-bulkhead/before/lib.pl' or die $@ || $!;

subtest 'Before: 正常系 — 全サービスが順番に動作する' => sub {
    my $pool   = SharedPool->new(max_size => 5);
    my $runner = ServiceRunner->new(pool => $pool);

    # 画像（acquire+release せず占有）→ 注文 → 通知
    is($runner->run_order_processing, 'order_done', '注文処理が成功');
    is($runner->run_notification, 'notify_done', '通知が成功');
    is($pool->available, 5, '解放後プールは満杯');
};

subtest 'Before: 問題点 — 画像変換がプールを占有すると他サービスが停止する' => sub {
    my $pool   = SharedPool->new(max_size => 3);
    my $runner = ServiceRunner->new(pool => $pool);

    # 画像変換が3回実行されプールを占有（releaseしない）
    $runner->run_image_processing for 1..3;
    is($pool->available, 0, 'プールが枯渇');

    # 注文処理が接続を取得できない
    eval { $runner->run_order_processing };
    like($@, qr/Pool exhausted/, '注文処理が拒否される');

    # 通知も同様
    eval { $runner->run_notification };
    like($@, qr/Pool exhausted/, '通知も拒否される');
};

subtest 'Before: 問題点 — 全サービスが同じプールを共有している' => sub {
    my $pool   = SharedPool->new(max_size => 5);
    my $runner = ServiceRunner->new(pool => $pool);

    # 画像変換が5枠すべて占有
    $runner->run_image_processing for 1..5;
    is($pool->available, 0, '画像変換が全枠を独占');

    my @log = $pool->log;
    my @acquired = grep { /^ACQUIRED:image$/ } @log;
    is(scalar @acquired, 5, '画像変換が5枠すべてを取得');
};

subtest 'Before: 問題点 — サービスごとの隔離がない' => sub {
    my $pool   = SharedPool->new(max_size => 2);
    my $runner = ServiceRunner->new(pool => $pool);

    # 画像変換が2枠占有
    $runner->run_image_processing for 1..2;

    # 注文処理も通知も全滅
    my $order_ok  = eval { $runner->run_order_processing; 1 };
    my $notify_ok = eval { $runner->run_notification; 1 };

    ok(!$order_ok, '注文処理が失敗');
    ok(!$notify_ok, '通知が失敗');

    my @log = $pool->log;
    my @rejected = grep { /^REJECTED:/ } @log;
    is(scalar @rejected, 2, '2件が拒否された');
};

done_testing;

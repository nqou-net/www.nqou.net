use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use Test::More;

do './agents/tests/code-detective-bulkhead/after/lib.pl' or die $@ || $!;

subtest 'After: 正常系 — Bulkhead 内でアクションが実行される' => sub {
    my $bh = Bulkhead->new(name => 'test', max_concurrent => 3);

    my $result = $bh->execute(sub { 'hello' });

    is($result, 'hello', 'アクションの結果が返る');
    is($bh->active_count, 0, '実行後のアクティブ数は0');
};

subtest 'After: 同時実行数が上限に達すると即座に拒否される' => sub {
    my $bh = Bulkhead->new(name => 'image', max_concurrent => 2);

    # 手動でアクティブ数を上限に設定（遅延リクエストの再現）
    $bh->_active_count(2);

    eval { $bh->execute(sub { 'should not run' }) };

    like($@, qr/Bulkhead 'image' is full \(2\/2\)/, '枠満杯で拒否');
    is($bh->active_count, 2, 'アクティブ数は変わらない');
};

subtest 'After: アクション内で例外が発生してもアクティブ数が解放される' => sub {
    my $bh = Bulkhead->new(name => 'test', max_concurrent => 3);

    eval { $bh->execute(sub { die "boom" }) };

    like($@, qr/boom/, '例外が伝播する');
    is($bh->active_count, 0, '例外後もアクティブ数は0に戻る');
};

subtest 'After: ログが正しく記録される' => sub {
    my $bh = Bulkhead->new(name => 'order', max_concurrent => 3);

    $bh->execute(sub { 'ok' });

    my @log = $bh->log;
    is($log[0], 'ADMITTED:order', '入室ログ');
    is($log[1], 'RELEASED:order', '退室ログ');
};

subtest 'After: 拒否時にもログが記録される' => sub {
    my $bh = Bulkhead->new(name => 'image', max_concurrent => 1);
    $bh->_active_count(1);

    eval { $bh->execute(sub { 'nope' }) };

    my @log = $bh->log;
    is($log[0], 'REJECTED:image', '拒否ログ');
};

subtest 'After: IsolatedServiceRunner — 各サービスが独立して動作する' => sub {
    my $runner = IsolatedServiceRunner->new;

    is($runner->run_image_processing, 'image_done', '画像変換が成功');
    is($runner->run_order_processing, 'order_done', '注文処理が成功');
    is($runner->run_notification, 'notify_done', '通知が成功');
};

subtest 'After: 画像変換の枠が満杯でも注文処理は独立して動作する' => sub {
    my $runner = IsolatedServiceRunner->new(
        image_bulkhead  => Bulkhead->new(name => 'image', max_concurrent => 2),
        order_bulkhead  => Bulkhead->new(name => 'order', max_concurrent => 3),
        notify_bulkhead => Bulkhead->new(name => 'notify', max_concurrent => 2),
    );

    # 画像変換の枠を満杯にする
    $runner->image_bulkhead->_active_count(2);

    # 画像変換は拒否される
    eval { $runner->run_image_processing };
    like($@, qr/Bulkhead 'image' is full/, '画像変換が拒否される');

    # 注文処理と通知は影響を受けない
    is($runner->run_order_processing, 'order_done', '注文処理は正常');
    is($runner->run_notification, 'notify_done', '通知も正常');
};

subtest 'After: 各 Bulkhead のアクティブ数は互いに独立している' => sub {
    my $runner = IsolatedServiceRunner->new(
        image_bulkhead  => Bulkhead->new(name => 'image', max_concurrent => 2),
        order_bulkhead  => Bulkhead->new(name => 'order', max_concurrent => 3),
        notify_bulkhead => Bulkhead->new(name => 'notify', max_concurrent => 2),
    );

    $runner->image_bulkhead->_active_count(2);

    is($runner->image_bulkhead->active_count, 2, '画像: アクティブ2');
    is($runner->order_bulkhead->active_count, 0, '注文: アクティブ0');
    is($runner->notify_bulkhead->active_count, 0, '通知: アクティブ0');
};

done_testing;

use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use Test::More;

do './agents/tests/code-detective-service-locator/before/lib.pl' or die $@ || $!;

subtest 'Before: 正常系 — ServiceLocator経由で注文が作成される' => sub {
    ServiceLocator->clear;
    my $db     = InMemoryDB->new;
    my $mailer = Mailer->new;
    ServiceLocator->register('db',     $db);
    ServiceLocator->register('mailer', $mailer);

    my $svc   = OrderService->new;
    my $order = $svc->place_order('ITEM-001', 3);

    is($order->{item_id},  'ITEM-001', '商品IDが正しい');
    is($order->{quantity}, 3,          '数量が正しい');
    is($db->count,         1,          'DBにレコードが1件');
    is($mailer->sent_count, 1,         'メールが1通送信された');
};

subtest 'Before: 未登録サービスの取得でdie' => sub {
    ServiceLocator->clear;

    eval { ServiceLocator->get('nonexistent') };
    like($@, qr/Service not found: nonexistent/, '未登録サービスでdie');
};

subtest 'Before: 問題点 — テスト間でグローバル状態が共有される' => sub {
    # テスト1で登録したDBが、テスト2でも残っている可能性を示す
    ServiceLocator->clear;
    my $db1 = InMemoryDB->new;
    ServiceLocator->register('db',     $db1);
    ServiceLocator->register('mailer', Mailer->new);

    my $svc1 = OrderService->new;
    $svc1->place_order('ITEM-A', 1);
    is($db1->count, 1, 'テスト1: DBに1件');

    # clear せずに新しいDBを登録しなければ、同じインスタンスを掴む
    my $db_from_locator = ServiceLocator->get('db');
    is($db_from_locator, $db1, '同一のDBインスタンスを取得してしまう');
    is($db_from_locator->count, 1, '前のテストのデータが残っている');
};

subtest 'Before: 問題点 — OrderServiceの依存がコンストラクタから見えない' => sub {
    # OrderService->new に引数がないため、何に依存しているか不明
    my $svc = OrderService->new;
    ok(!$svc->can('db'),     'dbアクセサが存在しない（依存が隠蔽）');
    ok(!$svc->can('mailer'), 'mailerアクセサが存在しない（依存が隠蔽）');
};

ServiceLocator->clear;  # グローバル状態をクリーンアップ
done_testing;

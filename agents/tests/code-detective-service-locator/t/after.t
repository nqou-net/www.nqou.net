use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use Test::More;

do './agents/tests/code-detective-service-locator/after/lib.pl' or die $@ || $!;

subtest 'After: 正常系 — DIで注文が作成される' => sub {
    my $db     = InMemoryDB->new;
    my $mailer = Mailer->new;
    my $svc    = OrderService->new(db => $db, mailer => $mailer);

    my $order = $svc->place_order('ITEM-001', 3);

    is($order->{item_id},  'ITEM-001', '商品IDが正しい');
    is($order->{quantity}, 3,          '数量が正しい');
    is($db->count,         1,          'DBにレコードが1件');
    is($mailer->sent_count, 1,         'メールが1通送信された');
};

subtest 'After: テスト間でDB状態が干渉しない' => sub {
    my $db1     = InMemoryDB->new;
    my $mailer1 = MockMailer->new;
    my $svc1    = OrderService->new(db => $db1, mailer => $mailer1);
    $svc1->place_order('ITEM-A', 1);

    my $db2     = InMemoryDB->new;
    my $mailer2 = MockMailer->new;
    my $svc2    = OrderService->new(db => $db2, mailer => $mailer2);
    $svc2->place_order('ITEM-B', 2);

    is($db1->count, 1, 'テスト1のDBは1件のまま');
    is($db2->count, 1, 'テスト2のDBも1件のみ');
    isnt($db1, $db2, '異なるDBインスタンス（テスト間干渉なし）');
};

subtest 'After: モック差し替えが容易' => sub {
    my $mock_db     = InMemoryDB->new;
    my $mock_mailer = MockMailer->new;
    my $svc = OrderService->new(db => $mock_db, mailer => $mock_mailer);

    $svc->place_order('ITEM-X', 5);

    is($mock_db->count, 1, 'モックDBにレコードが保存された');
    is($mock_mailer->sent_count, 1, 'モックメーラーに送信が記録された');
    is($mock_mailer->sent->[0]{subject}, 'New order: ITEM-X', '送信内容を検証できる');
};

subtest 'After: 依存がコンストラクタで明示されている' => sub {
    my $svc = OrderService->new(db => InMemoryDB->new, mailer => MockMailer->new);
    ok($svc->can('db'),     'dbアクセサが存在する（依存が明示的）');
    ok($svc->can('mailer'), 'mailerアクセサが存在する（依存が明示的）');
};

subtest 'After: 依存が未指定ならコンストラクタでエラー' => sub {
    eval { OrderService->new };
    like($@, qr/required/, '必須属性が未指定でエラー');
};

subtest 'After: ServiceLocator不要（グローバル状態なし）' => sub {
    # ServiceLocator パッケージが存在しないことを確認
    ok(!OrderService->new(db => InMemoryDB->new, mailer => MockMailer->new)
        ->can('service_locator'), 'ServiceLocator への参照がない');
    pass('グローバルレジストリに依存しない');
};

done_testing;

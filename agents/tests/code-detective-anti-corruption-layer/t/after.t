use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use Test::More;

do './agents/tests/code-detective-anti-corruption-layer/after/lib.pl' or die $@ || $!;

my $make_api = sub {
    my $api = WarehouseApi->new;
    $api->register_stock(1, {
        qty_avlbl => 50,
        lst_upd   => '20261503',  # YYYYDDMM: 2026年03月15日
        sts       => 1,
    });
    $api->register_stock(2, {
        qty_avlbl => 0,
        lst_upd   => '20260110',  # 2026年10月01日
        sts       => 0,
    });
    return $api;
};

subtest 'After: WarehouseTranslator — 外部形式を Stock に変換する' => sub {
    my $api        = $make_api->();
    my $translator = WarehouseTranslator->new(api => $api);
    my $stock      = $translator->fetch_stock(1);

    isa_ok($stock, 'Stock');
    is($stock->product_id, 1, '商品IDが正しい');
    is($stock->quantity, 50, '数量が正しい');
    ok($stock->available, '在庫あり');
    is($stock->updated_at, '2026-03-15', 'YYYYDDMM → YYYY-MM-DD に変換');
};

subtest 'After: WarehouseTranslator — 在庫なしも正しく変換する' => sub {
    my $api        = $make_api->();
    my $translator = WarehouseTranslator->new(api => $api);
    my $stock      = $translator->fetch_stock(2);

    is($stock->quantity, 0, '数量が0');
    ok(!$stock->available, '在庫なし');
    is($stock->updated_at, '2026-10-01', '日付が正しく変換');
};

subtest 'After: WarehouseTranslator — reduce_stock が外部形式に変換する' => sub {
    my $api        = $make_api->();
    my $translator = WarehouseTranslator->new(api => $api);

    $translator->reduce_stock(1, 5);

    my $log = $api->reduce_log;
    is($log->[0]{prd_id}, 1, '外部形式の prd_id');
    is($log->[0]{qty_rdc}, 5, '外部形式の qty_rdc');
    is($log->[0]{sts}, 1, '外部形式の sts');
};

subtest 'After: OrderService — 外部カラム名が一切登場しない' => sub {
    my $api        = $make_api->();
    my $translator = WarehouseTranslator->new(api => $api);
    my $service    = OrderService->new(warehouse => $translator);
    my $stock      = $service->check_availability(1);

    isa_ok($stock, 'Stock');
    is($stock->quantity, 50, 'ドメインの言語で数量にアクセス');
    ok($stock->available, 'ドメインの言語で在庫状態にアクセス');
};

subtest 'After: OrderService — 注文が処理される' => sub {
    my $api        = $make_api->();
    my $translator = WarehouseTranslator->new(api => $api);
    my $service    = OrderService->new(warehouse => $translator);
    my $result     = $service->place_order(1, 5);

    is($result->{result}, 'ok', '注文成功');
};

subtest 'After: OrderService — 在庫切れで例外' => sub {
    my $api        = $make_api->();
    my $translator = WarehouseTranslator->new(api => $api);
    my $service    = OrderService->new(warehouse => $translator);

    eval { $service->place_order(2, 1) };
    like($@, qr/Out of stock/, '在庫切れで例外');
};

subtest 'After: OrderService — 在庫不足で例外' => sub {
    my $api        = $make_api->();
    my $translator = WarehouseTranslator->new(api => $api);
    my $service    = OrderService->new(warehouse => $translator);

    eval { $service->place_order(1, 100) };
    like($@, qr/Insufficient stock/, '在庫不足で例外');
};

subtest 'After: 仕様変更シミュレーション — Translator だけ修正すれば済む' => sub {
    # 外部APIが qty_avlbl → quantity_available に変更したと仮定
    # Before: OrderService の check_availability を修正する必要がある
    # After: WarehouseTranslator の _to_stock だけ修正すれば済む

    # OrderService のソースに外部カラム名が含まれていないことを確認
    # （構造的に保証されている）
    my $api        = $make_api->();
    my $translator = WarehouseTranslator->new(api => $api);
    my $service    = OrderService->new(warehouse => $translator);

    # OrderService は Stock オブジェクトだけに依存
    my $stock = $service->check_availability(1);
    ok($stock->can('quantity'), 'ドメインの quantity メソッド');
    ok($stock->can('available'), 'ドメインの available メソッド');
    ok($stock->can('updated_at'), 'ドメインの updated_at メソッド');

    # 外部カラム名のメソッドは存在しない
    ok(!$stock->can('qty_avlbl'), '外部の qty_avlbl は存在しない');
    ok(!$stock->can('lst_upd'), '外部の lst_upd は存在しない');
    ok(!$stock->can('sts'), '外部の sts は存在しない');
};

done_testing;

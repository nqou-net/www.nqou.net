use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use Test::More;

do './agents/tests/code-detective-anti-corruption-layer/before/lib.pl' or die $@ || $!;

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

subtest 'Before: 正常系 — 在庫確認が動作する' => sub {
    my $api     = $make_api->();
    my $service = OrderService->new(warehouse_api => $api);
    my $stock   = $service->check_availability(1);

    is($stock->{quantity}, 50, '数量が正しい');
    ok($stock->{available}, '在庫あり');
    is($stock->{updated_at}, '2026-03-15', '日付が変換されている');
};

subtest 'Before: 正常系 — 注文が処理される' => sub {
    my $api     = $make_api->();
    my $service = OrderService->new(warehouse_api => $api);
    my $result  = $service->place_order(1, 5);

    is($result->{result}, 'ok', '注文成功');
    my $log = $api->reduce_log;
    is($log->[0]{prd_id}, 1, '外部形式で商品IDが送信される');
    is($log->[0]{qty_rdc}, 5, '外部形式で数量が送信される');
};

subtest 'Before: 在庫切れで例外' => sub {
    my $api     = $make_api->();
    my $service = OrderService->new(warehouse_api => $api);

    eval { $service->place_order(2, 1) };
    like($@, qr/Out of stock/, '在庫切れで例外');
};

subtest 'Before: 問題点 — 外部カラム名がドメインコードに露出している' => sub {
    my $api = $make_api->();
    my $raw = $api->get_stock(1);

    # 外部APIの独自カラム名
    ok(exists $raw->{qty_avlbl}, '外部の略語カラム qty_avlbl');
    ok(exists $raw->{lst_upd},   '外部の略語カラム lst_upd');
    ok(exists $raw->{sts},       '外部の略語カラム sts');

    # OrderService がこれらを直接参照している
    # → 外部API仕様変更時に OrderService の修正が必要
    pass('OrderService が外部形式を直接解釈している');
};

done_testing;

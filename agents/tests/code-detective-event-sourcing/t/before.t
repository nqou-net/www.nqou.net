use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use Test::More;

do './agents/tests/code-detective-event-sourcing/before/lib.pl' or die $@ || $!;

subtest 'Before: 基本動作 — 在庫の加算・減算' => sub {
    my $item = Item->new(id => '1', name => 'リンゴ');
    $item->add_stock(100);
    is($item->stock, 100, '100個入荷後は100個');

    $item->reduce_stock(30);
    is($item->stock, 70, '30個出荷後は70個');

    $item->reduce_stock(70);
    is($item->stock, 0, '70個出荷後は0個');
};

subtest 'Before: 在庫不足でダイ' => sub {
    my $item = Item->new(id => '2', name => 'バナナ', stock => 5);
    eval { $item->reduce_stock(10) };
    like($@, qr/在庫不足/, '在庫不足エラーが発生する');
};

subtest 'Before: PROBLEM — 履歴が残らない（上書きされる）' => sub {
    my $item = Item->new(id => '3', name => 'ミカン');
    $item->add_stock(200);
    $item->reduce_stock(50);
    $item->reduce_stock(30);
    $item->add_stock(10);

    is($item->stock, 130, '現在の在庫は130個');

    # 過去の状態を知る手段がない
    ok(!$item->can('history'), 'PROBLEM: history() メソッドが存在しない');

    # 「30個出荷した時点の在庫」を知ることができない
    ok(!$item->can('stock_at'), 'PROBLEM: stock_at() メソッドが存在しない');
};

subtest 'Before: PROBLEM — 誰が何をしたかの記録がゼロ' => sub {
    my $item = Item->new(id => '4', name => 'イチゴ');
    $item->add_stock(500);
    $item->reduce_stock(100);

    # stock は400だが、なぜ400なのか追えない
    is($item->stock, 400, '在庫400個 — だが経緯は闇の中');

    # 監査部門に提出できるデータが存在しない
    ok(!$item->can('history'), 'PROBLEM: 監査ログなし');
};

done_testing;

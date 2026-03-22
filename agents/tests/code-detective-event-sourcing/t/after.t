use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use Test::More;

do './agents/tests/code-detective-event-sourcing/after/lib.pl' or die $@ || $!;

subtest 'After: 基本動作 — 在庫の加算・減算' => sub {
    my $item = Item->new(id => '1', name => 'リンゴ');
    $item->add_stock(100);
    is($item->stock, 100, '100個入荷後は100個');

    $item->reduce_stock(30);
    is($item->stock, 70, '30個出荷後は70個');

    $item->reduce_stock(70);
    is($item->stock, 0, '70個出荷後は0個');
};

subtest 'After: 在庫不足でダイ' => sub {
    my $item = Item->new(id => '2', name => 'バナナ');
    $item->add_stock(5);
    eval { $item->reduce_stock(10) };
    like($@, qr/在庫不足/, '在庫不足エラーが発生する');
};

subtest 'After: FIX — 全イベント履歴が残る' => sub {
    my $item = Item->new(id => '3', name => 'ミカン');
    $item->add_stock(200);
    $item->reduce_stock(50);
    $item->reduce_stock(30);
    $item->add_stock(10);

    is($item->stock, 130, '現在の在庫は130個');

    my @history = $item->history;
    is(scalar @history, 4, 'FIX: 4件のイベントが記録されている');

    is($history[0]->type,     'added',   '1件目: added');
    is($history[0]->quantity, 200,       '1件目: 200個');
    is($history[1]->type,     'reduced', '2件目: reduced');
    is($history[1]->quantity, 50,        '2件目: 50個');
    is($history[2]->type,     'reduced', '3件目: reduced');
    is($history[2]->quantity, 30,        '3件目: 30個');
    is($history[3]->type,     'added',   '4件目: added');
    is($history[3]->quantity, 10,        '4件目: 10個');
};

subtest 'After: FIX — 任意時点の在庫を復元できる（time travel）' => sub {
    my $item = Item->new(id => '4', name => 'イチゴ');

    my $t0 = time();
    sleep(1);
    $item->add_stock(500);

    my $t1 = time();
    sleep(1);
    $item->reduce_stock(100);

    my $t2 = time();
    sleep(1);
    $item->reduce_stock(200);

    my $t3 = time();

    is($item->stock,       200, '現在の在庫: 200個 (500 - 100 - 200)');
    is($item->stock($t0),  0,   't0時点: 0個（何も起きていない）');
    is($item->stock($t1),  500, 't1時点: 500個（入荷後、出荷前）');
    is($item->stock($t2),  400, 't2時点: 400個（1回目の出荷後）');
    is($item->stock($t3),  200, 't3時点: 200個（2回目の出荷後）');
};

subtest 'After: FIX — StockEvent の属性が正しく設定される' => sub {
    my $item = Item->new(id => '5', name => 'ブドウ');
    my $before = time();
    $item->add_stock(50);
    my $after = time();

    my ($event) = $item->history;
    is($event->type,     'added', 'type は added');
    is($event->quantity, 50,      'quantity は 50');
    ok($event->occurred_at >= $before, 'occurred_at は入荷以降');
    ok($event->occurred_at <= $after,  'occurred_at は現在以前');
};

done_testing;

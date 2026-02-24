use v5.36;
use Test::More;
use lib 'lib';

use Waiter;
use Kitchen;
use Bar;
use Cashier;

# === セットアップ: 全員が全員を知っている ===
# （これが N×N 依存の元凶）
my $cashier = Cashier->new();
my $bar     = Bar->new(cashier => $cashier);
my $kitchen = Kitchen->new(bar => $bar, cashier => $cashier);
my $waiter  = Waiter->new(kitchen => $kitchen, bar => $bar, cashier => $cashier);

# ウェイター → キッチン（料理注文）
subtest 'food order flows to kitchen' => sub {
    my $results = $waiter->take_order({
        type  => 'food',
        item  => 'パスタ',
        table => 1,
    });
    is scalar $results->@*, 1, '結果は1つ';
    like $results->[0], qr/パスタ/, 'キッチンがパスタを調理';
};

# ウェイター → バー（ドリンク注文）
subtest 'drink order flows to bar' => sub {
    my $results = $waiter->take_order({
        type  => 'drink',
        item  => 'ジンジャーエール',
        table => 2,
    });
    is scalar $results->@*, 1, '結果は1つ';
    like $results->[0], qr/ジンジャーエール/, 'バーがドリンクを準備';
};

# ウェイター → キッチン＋バー（両方注文）
subtest 'both order flows to kitchen and bar' => sub {
    my $results = $waiter->take_order({
        type  => 'both',
        item  => 'ステーキ',
        table => 3,
    });
    is scalar $results->@*, 2, '結果は2つ（料理とドリンク）';
};

# 会計の伝票確認
subtest 'cashier tracks orders' => sub {
    my $result = $cashier->checkout(1);
    like $result, qr/1品/, 'テーブル1は1品';
};

done_testing;

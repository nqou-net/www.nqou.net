use v5.36;
use Test::More;
use lib 'lib';

use OrderMediator;
use Waiter;
use Kitchen;
use Bar;
use Cashier;
use Delivery;

# === セットアップ: Mediator に登録するだけ ===
# （各セクションは Mediator だけを知っている）
my $mediator = OrderMediator->new();
my $waiter   = Waiter->new();
my $kitchen  = Kitchen->new();
my $bar      = Bar->new();
my $cashier  = Cashier->new();

$mediator->register(waiter  => $waiter);
$mediator->register(kitchen => $kitchen);
$mediator->register(bar     => $bar);
$mediator->register(cashier => $cashier);

# ウェイター → Mediator → キッチン（料理注文）
subtest 'food order via mediator' => sub {
    my $results = $waiter->take_order({
        type  => 'food',
        item  => 'パスタ',
        table => 1,
    });
    is scalar $results->@*, 1, '結果は1つ';
    like $results->[0], qr/パスタ/, 'キッチンがパスタを調理';
};

# ウェイター → Mediator → バー（ドリンク注文）
subtest 'drink order via mediator' => sub {
    my $results = $waiter->take_order({
        type  => 'drink',
        item  => 'ジンジャーエール',
        table => 2,
    });
    is scalar $results->@*, 1, '結果は1つ';
    like $results->[0], qr/ジンジャーエール/, 'バーがドリンクを準備';
};

# ウェイター → Mediator → キッチン＋バー（両方注文）
subtest 'combo order via mediator' => sub {
    my $results = $waiter->take_order({
        type  => 'both',
        item  => 'ステーキ',
        table => 3,
    });
    is scalar $results->@*, 2, '結果は2つ（料理とドリンク）';
};

# 会計の伝票確認
subtest 'cashier tracks orders via mediator' => sub {
    my $results = $mediator->notify('checkout', { table => 1 });
    like $results->[0], qr/1品/, 'テーブル1は1品';
};

# === ★ 新セクション追加: Delivery ===
# 既存モジュールは何も変更せず、Mediator に登録するだけ！
subtest 'delivery section added without modifying existing code' => sub {
    my $delivery = Delivery->new();
    $mediator->register(delivery => $delivery);

    my $results = $mediator->notify('delivery_order', {
        item    => 'ピザ',
        address => '港区1-2-3',
        table   => 99,
    });

    ok scalar $results->@* >= 2, 'キッチン調理 + デリバリー手配';
    my $joined = join "\n", $results->@*;
    like $joined, qr/ピザ.*調理/,   'キッチンがピザを調理';
    like $joined, qr/港区.*配送手配/, 'デリバリーが配送を手配';
};

done_testing;

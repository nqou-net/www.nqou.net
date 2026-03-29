use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use Test::More;

do './agents/code-detective/tests/feature-envy/after/lib.pl' or die $@ || $!;

sub make_customer (%args) {
    return Customer->new(
        name            => $args{name}            // '田中太郎',
        email           => $args{email}           // 'tanaka@example.com',
        membership_tier => $args{membership_tier} // 'standard',
    );
}

sub make_order (%args) {
    my $customer = $args{customer} // make_customer();
    return Order->new(
        item_name  => $args{item_name}  // 'ウィジェットA',
        quantity   => $args{quantity}   // 3,
        unit_price => $args{unit_price} // 1000,
        customer   => $customer,
    );
}

# === Customer 単体テスト ===

subtest 'Customer: discount_rate — standard会員は0' => sub {
    my $c = make_customer(membership_tier => 'standard');
    is($c->discount_rate, 0, '割引率0');
};

subtest 'Customer: discount_rate — gold会員は0.1' => sub {
    my $c = make_customer(membership_tier => 'gold');
    is($c->discount_rate, 0.1, '割引率0.1');
};

subtest 'Customer: discount_rate — platinum会員は0.2' => sub {
    my $c = make_customer(membership_tier => 'platinum');
    is($c->discount_rate, 0.2, '割引率0.2');
};

subtest 'Customer: discount_rate — 未知の会員種別は0' => sub {
    my $c = make_customer(membership_tier => 'bronze');
    is($c->discount_rate, 0, '未知の種別は割引なし');
};

# === Order 単体テスト ===

subtest 'Order: subtotal — 数量 × 単価' => sub {
    my $order = make_order(quantity => 5, unit_price => 200);
    is($order->subtotal, 1000, '5 × 200 = 1000');
};

subtest 'Order: discount — Customerのdiscount_rateを使った計算' => sub {
    my $order = make_order(
        quantity   => 10,
        unit_price => 500,
        customer   => make_customer(membership_tier => 'gold'),
    );
    is($order->subtotal, 5000, '小計');
    is($order->discount, 500,  '10%割引');
    is($order->total,    4500, '合計');
};

subtest 'Order: total — standard会員は割引なし' => sub {
    my $order = make_order(
        quantity   => 2,
        unit_price => 1500,
        customer   => make_customer(membership_tier => 'standard'),
    );
    is($order->total, 3000, '割引なしの合計');
};

# === ReportGenerator テスト（handles による委譲） ===

subtest 'After: generate_summary — standard会員' => sub {
    my $order = make_order(customer => make_customer(membership_tier => 'standard'));
    my $report = ReportGenerator->new(order => $order);
    my $summary = $report->generate_summary;

    is($summary->{customer_name},  '田中太郎',          '顧客名');
    is($summary->{customer_email}, 'tanaka@example.com', 'メールアドレス');
    is($summary->{item},           'ウィジェットA',      '商品名');
    is($summary->{quantity},       3,                     '数量');
    is($summary->{subtotal},       3000,                  '小計');
    is($summary->{discount},       0,                     '割引なし');
    is($summary->{total},          3000,                  '合計');
};

subtest 'After: generate_summary — gold会員' => sub {
    my $order = make_order(customer => make_customer(membership_tier => 'gold'));
    my $report = ReportGenerator->new(order => $order);
    my $summary = $report->generate_summary;

    is($summary->{subtotal}, 3000, '小計');
    is($summary->{discount}, 300,  '10%割引');
    is($summary->{total},    2700, '合計');
};

subtest 'After: generate_summary — platinum会員' => sub {
    my $order = make_order(customer => make_customer(membership_tier => 'platinum'));
    my $report = ReportGenerator->new(order => $order);
    my $summary = $report->generate_summary;

    is($summary->{subtotal}, 3000, '小計');
    is($summary->{discount}, 600,  '20%割引');
    is($summary->{total},    2400, '合計');
};

# === handles の委譲テスト ===

subtest 'After: handles — ReportGenerator から直接委譲メソッドが呼べる' => sub {
    my $order = make_order();
    my $report = ReportGenerator->new(order => $order);

    is($report->item_name,      'ウィジェットA', 'item_name 委譲');
    is($report->quantity,       3,                'quantity 委譲');
    is($report->subtotal,       3000,             'subtotal 委譲');
    is($report->customer_name,  '田中太郎',      'customer_name 委譲');
    is($report->customer_email, 'tanaka@example.com', 'customer_email 委譲');
};

done_testing;

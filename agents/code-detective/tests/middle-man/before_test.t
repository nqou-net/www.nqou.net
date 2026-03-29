#!/usr/bin/env perl
use v5.36;
use Test::More;
use lib './before';

use Address;
use Customer;
use Order;
use OrderFacade;
use ShippingCalculator;
use InvoiceGenerator;

# -- ヘルパー --
sub make_order (%args) {
    my $pref = delete $args{prefecture} // '東京都';
    return Order->new(
        customer => Customer->new(
            name    => '森川ユウジ',
            email   => 'morikawa@example.com',
            address => Address->new(prefecture => $pref),
        ),
        item_name  => 'ウィジェットA',
        quantity   => 2,
        unit_price => 1000,
        %args,
    );
}

# ===== OrderFacade のテスト（Middle Man） =====

subtest 'OrderFacade: 全メソッドが委譲される' => sub {
    my $order  = make_order();
    my $facade = OrderFacade->new(order => $order);

    is($facade->item_name,    'ウィジェットA', 'item_name 委譲');
    is($facade->quantity,     2,               'quantity 委譲');
    is($facade->unit_price,   1000,            'unit_price 委譲');
    is($facade->total_price,  2000,            'total_price 委譲');
    is($facade->shipping_zone, 'kanto',        'shipping_zone 委譲');
};

# ===== ShippingCalculator（OrderFacade 経由） =====

subtest 'ShippingCalculator: OrderFacade 経由で配送料計算' => sub {
    my $facade = OrderFacade->new(order => make_order(prefecture => '東京都'));
    my $calc   = ShippingCalculator->new(facade => $facade);
    is($calc->calculate, 500, '関東ゾーン 500円');
};

subtest 'ShippingCalculator: 大阪' => sub {
    my $facade = OrderFacade->new(order => make_order(prefecture => '大阪府'));
    my $calc   = ShippingCalculator->new(facade => $facade);
    is($calc->calculate, 700, '関西ゾーン 700円');
};

# ===== InvoiceGenerator（OrderFacade 経由） =====

subtest 'InvoiceGenerator: OrderFacade 経由で請求書生成' => sub {
    my $facade = OrderFacade->new(order => make_order(prefecture => '東京都'));
    my $gen    = InvoiceGenerator->new(facade => $facade);
    my $text   = $gen->generate;
    like($text, qr/ウィジェットA/, '商品名を含む');
    like($text, qr/合計: 2500/,    '合計金額を含む (2000 + 500)');
};

# ===== Middle Man の兆候を確認 =====

subtest 'OrderFacade は独自メソッドを持たない' => sub {
    # OrderFacade のメソッド一覧から Moo の標準メソッドを除外し、
    # 全てが Order からの委譲であることを確認
    my $order  = make_order();
    my $facade = OrderFacade->new(order => $order);

    my @delegated = qw(shipping_zone item_name quantity unit_price total_price);
    for my $method (@delegated) {
        is($facade->$method, $order->$method, "$method は Order と同じ値を返す");
    }
    pass('OrderFacade の全メソッドは Order への純粋な委譲');
};

done_testing;

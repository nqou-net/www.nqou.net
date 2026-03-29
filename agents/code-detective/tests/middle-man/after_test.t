#!/usr/bin/env perl
use v5.36;
use Test::More;
use lib './after';

use Address;
use Customer;
use Order;
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

# ===== Order のテスト =====

subtest 'Order: 基本属性と計算' => sub {
    my $order = make_order();
    is($order->item_name,      'ウィジェットA', 'item_name');
    is($order->quantity,       2,               'quantity');
    is($order->unit_price,     1000,            'unit_price');
    is($order->total_price,    2000,            'total_price');
    is($order->shipping_zone,  'kanto',         'shipping_zone は Customer から委譲');
};

# ===== ShippingCalculator（Order 直接使用） =====

subtest 'ShippingCalculator: Order を直接使って配送料計算' => sub {
    my $order = make_order(prefecture => '東京都');
    my $calc  = ShippingCalculator->new(order => $order);
    is($calc->calculate, 500, '関東ゾーン 500円');
};

subtest 'ShippingCalculator: 大阪' => sub {
    my $order = make_order(prefecture => '大阪府');
    my $calc  = ShippingCalculator->new(order => $order);
    is($calc->calculate, 700, '関西ゾーン 700円');
};

subtest 'ShippingCalculator: 北海道' => sub {
    my $order = make_order(prefecture => '北海道');
    my $calc  = ShippingCalculator->new(order => $order);
    is($calc->calculate, 1000, 'otherゾーン 1000円');
};

# ===== InvoiceGenerator（Order 直接使用） =====

subtest 'InvoiceGenerator: Order を直接使って請求書生成' => sub {
    my $order = make_order(prefecture => '東京都');
    my $gen   = InvoiceGenerator->new(order => $order);
    my $text  = $gen->generate;
    like($text, qr/ウィジェットA/, '商品名を含む');
    like($text, qr/合計: 2500/,    '合計金額を含む (2000 + 500)');
};

# ===== OrderFacade が存在しないことの確認 =====

subtest 'OrderFacade は不要になった' => sub {
    # After コードでは OrderFacade.pm が存在しない
    ok(!eval { require OrderFacade; 1 }, 'OrderFacade は読み込めない（除去済み）');
};

done_testing;

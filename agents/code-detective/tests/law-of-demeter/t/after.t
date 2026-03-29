use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use Test::More;

do './agents/code-detective/tests/law-of-demeter/after/lib.pl' or die $@ || $!;

sub make_address (%args) {
    return Address->new(
        prefecture => $args{prefecture} // '東京都',
    );
}

sub make_customer (%args) {
    my $address = $args{address} // make_address();
    return Customer->new(
        name    => $args{name}    // '森川ユウジ',
        email   => $args{email}   // 'morikawa@example.com',
        address => $address,
    );
}

sub make_order (%args) {
    my $customer = $args{customer} // make_customer();
    return Order->new(
        item_name  => $args{item_name}  // 'ウィジェットA',
        quantity   => $args{quantity}   // 1,
        unit_price => $args{unit_price} // 1000,
        customer   => $customer,
    );
}

# === Address 単体テスト ===

subtest 'Address: shipping_zone — 東京都はkanto' => sub {
    my $addr = make_address(prefecture => '東京都');
    is($addr->shipping_zone, 'kanto', '関東ゾーン');
};

subtest 'Address: shipping_zone — 神奈川県はkanto' => sub {
    my $addr = make_address(prefecture => '神奈川県');
    is($addr->shipping_zone, 'kanto', '関東ゾーン');
};

subtest 'Address: shipping_zone — 千葉県はkanto' => sub {
    my $addr = make_address(prefecture => '千葉県');
    is($addr->shipping_zone, 'kanto', '関東ゾーン');
};

subtest 'Address: shipping_zone — 大阪府はkansai' => sub {
    my $addr = make_address(prefecture => '大阪府');
    is($addr->shipping_zone, 'kansai', '関西ゾーン');
};

subtest 'Address: shipping_zone — 京都府はkansai' => sub {
    my $addr = make_address(prefecture => '京都府');
    is($addr->shipping_zone, 'kansai', '関西ゾーン');
};

subtest 'Address: shipping_zone — 北海道はother' => sub {
    my $addr = make_address(prefecture => '北海道');
    is($addr->shipping_zone, 'other', 'otherゾーン');
};

# === Customer 委譲テスト ===

subtest 'Customer: handles — shipping_zoneが委譲される' => sub {
    my $customer = make_customer(
        address => make_address(prefecture => '大阪府'),
    );
    is($customer->shipping_zone, 'kansai', 'Customer経由で関西ゾーン');
};

# === Order 委譲テスト ===

subtest 'Order: handles — shipping_zoneが委譲される' => sub {
    my $order = make_order(
        customer => make_customer(
            address => make_address(prefecture => '東京都'),
        ),
    );
    is($order->shipping_zone, 'kanto', 'Order経由で関東ゾーン');
};

# === ShippingCalculator テスト（handles による委譲） ===

subtest 'After: handles — shipping_zoneが委譲される' => sub {
    my $order = make_order(
        customer => make_customer(
            address => make_address(prefecture => '千葉県'),
        ),
    );
    my $calc = ShippingCalculator->new(order => $order);
    is($calc->shipping_zone, 'kanto', 'ShippingCalculator経由で関東ゾーン');
};

subtest 'After: 東京都 — 関東ゾーン 500円' => sub {
    my $order = make_order(
        customer => make_customer(address => make_address(prefecture => '東京都')),
    );
    my $calc = ShippingCalculator->new(order => $order);
    is($calc->calculate, 500, '関東ゾーン');
};

subtest 'After: 大阪府 — 関西ゾーン 700円' => sub {
    my $order = make_order(
        customer => make_customer(address => make_address(prefecture => '大阪府')),
    );
    my $calc = ShippingCalculator->new(order => $order);
    is($calc->calculate, 700, '関西ゾーン');
};

subtest 'After: 北海道 — otherゾーン 1000円' => sub {
    my $order = make_order(
        customer => make_customer(address => make_address(prefecture => '北海道')),
    );
    my $calc = ShippingCalculator->new(order => $order);
    is($calc->calculate, 1000, 'otherゾーン');
};

done_testing;

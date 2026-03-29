use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use Test::More;

do './agents/code-detective/tests/law-of-demeter/before/lib.pl' or die $@ || $!;

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

subtest 'Before: 東京都 — 関東ゾーン 500円' => sub {
    my $order = make_order(
        customer => make_customer(address => make_address(prefecture => '東京都')),
    );
    my $calc = ShippingCalculator->new(order => $order);
    is($calc->calculate, 500, '関東ゾーン');
};

subtest 'Before: 神奈川県 — 関東ゾーン 500円' => sub {
    my $order = make_order(
        customer => make_customer(address => make_address(prefecture => '神奈川県')),
    );
    my $calc = ShippingCalculator->new(order => $order);
    is($calc->calculate, 500, '関東ゾーン');
};

subtest 'Before: 大阪府 — 関西ゾーン 700円' => sub {
    my $order = make_order(
        customer => make_customer(address => make_address(prefecture => '大阪府')),
    );
    my $calc = ShippingCalculator->new(order => $order);
    is($calc->calculate, 700, '関西ゾーン');
};

subtest 'Before: 北海道 — otherゾーン 1000円' => sub {
    my $order = make_order(
        customer => make_customer(address => make_address(prefecture => '北海道')),
    );
    my $calc = ShippingCalculator->new(order => $order);
    is($calc->calculate, 1000, 'otherゾーン');
};

done_testing;

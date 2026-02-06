use v5.36;
use Test2::V0;
use lib 'lib';
use Store::Cart;

subtest 'Summer Campaign' => sub {
    my $cart = Store::Cart->new(
        campaign_id => 'SUMMER_2026',
        member_rank => 'GOLD',
    );
    $cart->add_item('T-Shirt', 3000, 'CLOTHING');    # 3000 * 0.8 = 2400
    $cart->add_item('Apple',   200,  'FOOD');        # 200 (No discount)

    is($cart->calculate_total(), 2600, 'Gold member gets 20% off clothing, no discount on food');
};

subtest 'Summer Campaign with Coupon' => sub {
    my $cart = Store::Cart->new(
        campaign_id => 'SUMMER_2026',
        member_rank => 'BRONZE',
        coupon_code => 'SUMMER_FOOD',
    );
    $cart->add_item('Apple', 200, 'FOOD');           # 200 * 0.95 = 190

    is($cart->calculate_total(), 190, 'Food coupon works');
};

subtest 'Winter Campaign' => sub {
    my $cart = Store::Cart->new(
        campaign_id => 'WINTER_2026',
        member_rank => 'GOLD',
    );
    $cart->add_item('TV', 50000, 'ELECTRONICS');     # 50000 * 0.9 = 45000 - 500 = 44500

    is($cart->calculate_total(), 44500, 'Winter electronics discount');
};

subtest 'Normal Day' => sub {
    my $cart = Store::Cart->new(
        member_rank => 'GOLD',
        today       => '2026-05-10',
    );
    $cart->add_item('Book', 2000, 'BOOK');           # 2000 * 0.98 = 1960

    is($cart->calculate_total(), 1960, 'Normal Gold discount');
};

subtest '5th Day Discount' => sub {
    my $cart = Store::Cart->new(
        member_rank => 'BRONZE',
        today       => '2026-05-05',
    );
    $cart->add_item('Game', 5000, 'GAME');           # 5000 - 100 = 4900

    is($cart->calculate_total(), 4900, '5th day discount applied');
};

done_testing;

use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

# ===== Address (shipping_zone を自クラスに) =====
package Address;
use Moo;

has prefecture => (is => 'ro', required => 1);

sub shipping_zone ($self) {
    my %zone = (
        '東京都'   => 'kanto',
        '神奈川県' => 'kanto',
        '千葉県'   => 'kanto',
        '大阪府'   => 'kansai',
        '京都府'   => 'kansai',
    );
    return $zone{$self->prefecture} // 'other';
}

# ===== Customer (handles で Address の shipping_zone を委譲) =====
package Customer;
use Moo;

has name    => (is => 'ro', required => 1);
has email   => (is => 'ro', required => 1);
has address => (
    is       => 'ro',
    required => 1,
    handles  => [qw(shipping_zone)],
);

# ===== Order (handles で Customer の shipping_zone を委譲) =====
package Order;
use Moo;

has item_name  => (is => 'ro', required => 1);
has quantity   => (is => 'ro', required => 1);
has unit_price => (is => 'ro', required => 1);
has customer   => (
    is       => 'ro',
    required => 1,
    handles  => [qw(shipping_zone)],
);

# ===== ShippingCalculator (handles で Order の shipping_zone を委譲) =====
package ShippingCalculator;
use Moo;

has order => (
    is       => 'ro',
    required => 1,
    handles  => [qw(shipping_zone)],
);

sub calculate ($self) {
    my %rate = (kanto => 500, kansai => 700, other => 1000);
    return $rate{$self->shipping_zone};
}

1;

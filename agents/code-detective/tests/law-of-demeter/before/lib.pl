use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

# ===== Address =====
package Address;
use Moo;

has prefecture => (is => 'ro', required => 1);

# ===== Customer =====
package Customer;
use Moo;

has name    => (is => 'ro', required => 1);
has email   => (is => 'ro', required => 1);
has address => (is => 'ro', required => 1);

# ===== Order =====
package Order;
use Moo;

has item_name  => (is => 'ro', required => 1);
has quantity   => (is => 'ro', required => 1);
has unit_price => (is => 'ro', required => 1);
has customer   => (is => 'ro', required => 1);

# ===== ShippingCalculator (Train Wreck / LoD 違反) =====
package ShippingCalculator;
use Moo;

has order => (is => 'ro', required => 1);

sub calculate ($self) {
    # Train Wreck: 4段のメソッドチェーン
    my $pref = $self->order->customer->address->prefecture;
    my %zone = (
        '東京都'   => 'kanto',
        '神奈川県' => 'kanto',
        '千葉県'   => 'kanto',
        '大阪府'   => 'kansai',
        '京都府'   => 'kansai',
    );
    my $zone = $zone{$pref} // 'other';
    my %rate = (kanto => 500, kansai => 700, other => 1000);
    return $rate{$zone};
}

1;

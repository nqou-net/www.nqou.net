use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

# ===== Customer =====
package Customer;
use Moo;

has name            => (is => 'ro', required => 1);
has email           => (is => 'ro', required => 1);
has membership_tier => (is => 'ro', default => 'standard');

# ===== Order =====
package Order;
use Moo;

has item_name  => (is => 'ro', required => 1);
has quantity   => (is => 'ro', required => 1);
has unit_price => (is => 'ro', required => 1);
has customer   => (is => 'ro', required => 1);

# ===== ReportGenerator (Feature Envy) =====
package ReportGenerator;
use Moo;

has order => (is => 'ro', required => 1);

sub generate_summary ($self) {
    # Feature Envy: $self のデータを一切使わず、
    # order と customer のゲッターばかり呼ぶ
    my $item_name  = $self->order->item_name;
    my $quantity   = $self->order->quantity;
    my $unit_price = $self->order->unit_price;
    my $subtotal   = $quantity * $unit_price;

    my $name  = $self->order->customer->name;
    my $email = $self->order->customer->email;
    my $tier  = $self->order->customer->membership_tier;

    my $discount = 0;
    if ($tier eq 'gold') {
        $discount = $subtotal * 0.1;
    }
    elsif ($tier eq 'platinum') {
        $discount = $subtotal * 0.2;
    }

    my $total = $subtotal - $discount;

    return {
        customer_name  => $name,
        customer_email => $email,
        item           => $item_name,
        quantity       => $quantity,
        subtotal       => $subtotal,
        discount       => $discount,
        total          => $total,
    };
}

1;

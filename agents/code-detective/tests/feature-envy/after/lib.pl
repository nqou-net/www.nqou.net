use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

# ===== Customer (Move Method: discount_rate を自クラスに) =====
package Customer;
use Moo;

has name            => (is => 'ro', required => 1);
has email           => (is => 'ro', required => 1);
has membership_tier => (is => 'ro', default => 'standard');

sub discount_rate ($self) {
    my %rates = (gold => 0.1, platinum => 0.2);
    return $rates{$self->membership_tier} // 0;
}

# ===== Order (Move Method: subtotal/discount/total を自クラスに) =====
package Order;
use Moo;

has item_name  => (is => 'ro', required => 1);
has quantity   => (is => 'ro', required => 1);
has unit_price => (is => 'ro', required => 1);
has customer   => (is => 'ro', required => 1);

sub subtotal ($self) {
    return $self->quantity * $self->unit_price;
}

sub discount ($self) {
    return $self->subtotal * $self->customer->discount_rate;
}

sub total ($self) {
    return $self->subtotal - $self->discount;
}

# ===== ReportGenerator (handles で委譲、Feature Envy 解消) =====
package ReportGenerator;
use Moo;

has order => (
    is       => 'ro',
    required => 1,
    handles  => [qw(item_name quantity subtotal discount total)],
);

has _customer => (
    is      => 'lazy',
    builder => sub ($self) { $self->order->customer },
    handles => {
        customer_name  => 'name',
        customer_email => 'email',
    },
);

sub generate_summary ($self) {
    return {
        customer_name  => $self->customer_name,
        customer_email => $self->customer_email,
        item           => $self->item_name,
        quantity       => $self->quantity,
        subtotal       => $self->subtotal,
        discount       => $self->discount,
        total          => $self->total,
    };
}

1;

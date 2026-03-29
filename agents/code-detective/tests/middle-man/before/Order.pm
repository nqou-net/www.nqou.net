package Order;
use v5.36;
use Moo;

has customer   => (
    is       => 'ro',
    required => 1,
    handles  => [qw(shipping_zone)],
);
has item_name  => (is => 'ro', required => 1);
has quantity   => (is => 'ro', required => 1);
has unit_price => (is => 'ro', required => 1);

sub total_price ($self) {
    return $self->quantity * $self->unit_price;
}

1;

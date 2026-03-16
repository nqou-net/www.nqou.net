package OrderState::Paid;
use Moo;
with 'OrderState';
use OrderState::Shipped;
use OrderState::Cancelled;

sub process_payment {
    my ($self, $order) = @_;
    die "Order is already paid.";
}

sub ship_item {
    my ($self, $order) = @_;
    $order->state(OrderState::Shipped->new);
    return "Item shipped successfully.";
}

sub cancel {
    my ($self, $order) = @_;
    $order->state(OrderState::Cancelled->new);
    return "Order cancelled.";
}

sub status_name { 'paid' }

1;

package OrderState::Unpaid;
use Moo;
with 'OrderState';
use OrderState::Paid;
use OrderState::Cancelled;

sub process_payment {
    my ($self, $order) = @_;
    $order->state(OrderState::Paid->new);
    return "Payment processed successfully.";
}

sub ship_item {
    my ($self, $order) = @_;
    die "Cannot ship an unpaid order.";
}

sub cancel {
    my ($self, $order) = @_;
    $order->state(OrderState::Cancelled->new);
    return "Order cancelled.";
}

sub status_name { 'unpaid' }

1;

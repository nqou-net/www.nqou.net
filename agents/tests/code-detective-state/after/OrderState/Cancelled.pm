package OrderState::Cancelled;
use Moo;
with 'OrderState';

sub process_payment {
    my ($self, $order) = @_;
    die "Cannot pay for a cancelled order.";
}

sub ship_item {
    my ($self, $order) = @_;
    die "Cannot ship a cancelled order.";
}

sub cancel {
    my ($self, $order) = @_;
    die "Order is already cancelled.";
}

sub status_name { 'cancelled' }

1;

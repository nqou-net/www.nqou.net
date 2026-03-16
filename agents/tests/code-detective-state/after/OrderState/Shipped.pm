package OrderState::Shipped;
use Moo;
with 'OrderState';

sub process_payment {
    my ($self, $order) = @_;
    die "Cannot pay for a shipped order.";
}

sub ship_item {
    my ($self, $order) = @_;
    die "Order is already shipped.";
}

sub cancel {
    my ($self, $order) = @_;
    die "Cannot cancel a shipped order.";
}

sub status_name { 'shipped' }

1;

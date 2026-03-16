package Order;
use Moo;
use strict;
use warnings;

has status => (
    is      => 'rw',
    default => 'unpaid', # unpaid, paid, shipped, cancelled
);

sub process_payment {
    my ($self) = @_;
    if ($self->status eq 'unpaid') {
        $self->status('paid');
        return "Payment processed successfully.";
    } elsif ($self->status eq 'paid') {
        die "Order is already paid.";
    } elsif ($self->status eq 'shipped') {
        die "Cannot pay for a shipped order.";
    } elsif ($self->status eq 'cancelled') {
        die "Cannot pay for a cancelled order.";
    } else {
        die "Unknown status.";
    }
}

sub ship_item {
    my ($self) = @_;
    if ($self->status eq 'unpaid') {
        die "Cannot ship an unpaid order.";
    } elsif ($self->status eq 'paid') {
        $self->status('shipped');
        return "Item shipped successfully.";
    } elsif ($self->status eq 'shipped') {
        die "Order is already shipped.";
    } elsif ($self->status eq 'cancelled') {
        die "Cannot ship a cancelled order.";
    } else {
        die "Unknown status.";
    }
}

sub cancel {
    my ($self) = @_;
    if ($self->status eq 'unpaid' || $self->status eq 'paid') {
        $self->status('cancelled');
        return "Order cancelled.";
    } elsif ($self->status eq 'shipped') {
        die "Cannot cancel a shipped order.";
    } elsif ($self->status eq 'cancelled') {
        die "Order is already cancelled.";
    } else {
        die "Unknown status.";
    }
}

1;

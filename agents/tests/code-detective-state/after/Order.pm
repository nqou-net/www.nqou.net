package Order;
use Moo;
use strict;
use warnings;
use OrderState::Unpaid;

has state => (
    is      => 'rw',
    default => sub { OrderState::Unpaid->new },
);

sub process_payment {
    my ($self) = @_;
    return $self->state->process_payment($self);
}

sub ship_item {
    my ($self) = @_;
    return $self->state->ship_item($self);
}

sub cancel {
    my ($self) = @_;
    return $self->state->cancel($self);
}

# For test compatibility with before
sub status {
    my ($self) = @_;
    return $self->state->status_name;
}

1;

use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

package Colleague {
    use Moo::Role;

    has mediator => ( is => 'rw', weak_ref => 1 );

    sub send_event ($self, $event, $data) {
        $self->mediator->relay($event, $self, $data);
    }
}

package AuditLogger {
    use Moo;
    with 'Colleague';

    has logs => ( is => 'ro', default => sub { [] } );

    sub log ($self, $event, $data) {
        push $self->logs->@*, { event => $event, data => $data };
    }
}

package NotificationService {
    use Moo;
    with 'Colleague';

    has messages => ( is => 'ro', default => sub { [] } );

    sub notify ($self, $message) {
        push $self->messages->@*, $message;
    }
}

package InventoryManager {
    use Moo;
    with 'Colleague';

    has stock => ( is => 'ro', default => sub { {} } );

    sub reserve ($self, $order) {
        my $item = $order->{item_id};
        $self->stock->{$item} = ($self->stock->{$item} // 10) - $order->{quantity};
        if ($self->stock->{$item} < 3) {
            $self->send_event('low_stock', $order);
        }
    }

    sub release ($self, $order) {
        my $item = $order->{item_id};
        $self->stock->{$item} = ($self->stock->{$item} // 0) + $order->{quantity};
    }
}

package PaymentGateway {
    use Moo;
    with 'Colleague';

    has should_fail => ( is => 'rw', default => 0 );

    sub charge ($self, $order) {
        my $success = $self->_process_payment($order);
        if (!$success) {
            $self->send_event('payment_failed', $order);
        }
        return $success;
    }

    sub _process_payment ($self, $order) { !$self->should_fail }
}

package OrderManager {
    use Moo;
    with 'Colleague';

    sub place_order ($self, $order) {
        $self->send_event('order_placed', $order);
    }
}

package CouponEngine {
    use Moo;
    with 'Colleague';

    sub apply ($self, $order) {
        if (my $code = $order->{coupon_code}) {
            $order->{discount} = $self->_calculate_discount($code);
            $self->send_event('coupon_applied', $order);
        }
    }

    sub _calculate_discount ($self, $code) { 500 }
}

package OrderMediator {
    use Moo;

    has colleagues => ( is => 'ro', default => sub { {} } );

    sub register ($self, $name, $colleague) {
        $self->colleagues->{$name} = $colleague;
        $colleague->mediator($self);
        return $self;
    }

    sub relay ($self, $event, $sender, $data) {
        my $c = $self->colleagues;

        if ($event eq 'order_placed') {
            $c->{coupon}->apply($data) if $c->{coupon} && $data->{coupon_code};
            $c->{inventory}->reserve($data);
            $c->{payment}->charge($data);
            $c->{notification}->notify("注文確定: $data->{id}");
            $c->{audit}->log('order_placed', $data);
        }
        elsif ($event eq 'low_stock') {
            $c->{notification}->notify("在庫残少: $data->{item_id}");
            $c->{audit}->log('low_stock', $data);
        }
        elsif ($event eq 'payment_failed') {
            $c->{inventory}->release($data);
            $c->{notification}->notify("決済失敗: $data->{id}");
            $c->{audit}->log('payment_failed', $data);
        }
        elsif ($event eq 'coupon_applied') {
            $c->{notification}->notify("クーポン適用: $data->{coupon_code}");
            $c->{audit}->log('coupon_applied', $data);
        }
    }
}

1;

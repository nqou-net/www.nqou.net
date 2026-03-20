use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

package AuditLogger {
    use Moo;

    has logs => ( is => 'ro', default => sub { [] } );

    sub log ($self, $event, $data) {
        push $self->logs->@*, { event => $event, data => $data };
    }
}

package NotificationService {
    use Moo;

    has audit    => ( is => 'rw' );
    has messages => ( is => 'ro', default => sub { [] } );

    sub notify ($self, $message) {
        push $self->messages->@*, $message;
        $self->audit->log('notification_sent', { message => $message });
    }
}

package InventoryManager {
    use Moo;

    has notification => ( is => 'rw' );
    has audit        => ( is => 'rw' );
    has stock        => ( is => 'ro', default => sub { {} } );

    sub reserve ($self, $order) {
        my $item = $order->{item_id};
        $self->stock->{$item} = ($self->stock->{$item} // 10) - $order->{quantity};
        if ($self->stock->{$item} < 3) {
            $self->notification->notify("在庫残少: $item");
            $self->audit->log('low_stock', $order);
        }
    }

    sub release ($self, $order) {
        my $item = $order->{item_id};
        $self->stock->{$item} = ($self->stock->{$item} // 0) + $order->{quantity};
        $self->audit->log('stock_released', $order);
    }
}

package PaymentGateway {
    use Moo;

    has inventory    => ( is => 'rw' );
    has notification => ( is => 'rw' );
    has audit        => ( is => 'rw' );
    has should_fail  => ( is => 'rw', default => 0 );

    sub charge ($self, $order) {
        my $success = $self->_process_payment($order);
        if (!$success) {
            $self->inventory->release($order);
            $self->notification->notify("決済失敗: $order->{id}");
        }
        $self->audit->log('payment_processed', { order => $order, success => $success });
        return $success;
    }

    sub _process_payment ($self, $order) { !$self->should_fail }
}

package OrderManager {
    use Moo;

    has inventory    => ( is => 'rw' );
    has payment      => ( is => 'rw' );
    has notification => ( is => 'rw' );
    has audit        => ( is => 'rw' );

    sub place_order ($self, $order) {
        $self->inventory->reserve($order);
        $self->payment->charge($order);
        $self->notification->notify("注文確定: $order->{id}");
        $self->audit->log('order_placed', $order);
    }
}

1;

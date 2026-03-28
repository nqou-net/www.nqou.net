use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

# === After: Saga（補償トランザクション付きオーケストレーション） ===
# 各ステップの成功後に補償手順を登録し、途中失敗時には逆順で巻き戻す。

# --- PaymentService（決済サービスのスタブ） ---
package PaymentService {
    use Moo;
    has charges  => (is => 'rw', default => sub { [] });
    has refunds  => (is => 'rw', default => sub { [] });
    has should_fail => (is => 'rw', default => 0);

    sub charge ($self, $amount) {
        die "Payment declined\n" if $self->should_fail;
        my $payment = { id => 'PAY-' . (scalar @{ $self->charges } + 1), amount => $amount };
        push @{ $self->charges }, $payment;
        return $payment;
    }

    sub refund ($self, $payment_id) {
        push @{ $self->refunds }, { payment_id => $payment_id };
    }

    sub charge_count ($self) { scalar @{ $self->charges } }
    sub refund_count ($self) { scalar @{ $self->refunds } }
}

# --- InventoryService（在庫サービスのスタブ） ---
package InventoryService {
    use Moo;
    has reservations => (is => 'rw', default => sub { [] });
    has releases     => (is => 'rw', default => sub { [] });
    has should_fail  => (is => 'rw', default => 0);

    sub reserve ($self, $item_id, $quantity) {
        die "Out of stock\n" if $self->should_fail;
        my $reservation = { id => 'RES-' . (scalar @{ $self->reservations } + 1), item_id => $item_id, quantity => $quantity };
        push @{ $self->reservations }, $reservation;
        return $reservation;
    }

    sub release ($self, $reservation_id) {
        push @{ $self->releases }, { reservation_id => $reservation_id };
    }

    sub reservation_count ($self) { scalar @{ $self->reservations } }
    sub release_count ($self)     { scalar @{ $self->releases } }
}

# --- ShippingService（配送サービスのスタブ） ---
package ShippingService {
    use Moo;
    has shipments    => (is => 'rw', default => sub { [] });
    has cancellations => (is => 'rw', default => sub { [] });
    has should_fail  => (is => 'rw', default => 0);

    sub schedule ($self, $address) {
        die "Shipping unavailable\n" if $self->should_fail;
        my $shipment = { id => 'SHIP-' . (scalar @{ $self->shipments } + 1), address => $address };
        push @{ $self->shipments }, $shipment;
        return $shipment;
    }

    sub cancel ($self, $shipment_id) {
        push @{ $self->cancellations }, { shipment_id => $shipment_id };
    }

    sub shipment_count ($self)     { scalar @{ $self->shipments } }
    sub cancellation_count ($self) { scalar @{ $self->cancellations } }
}

# --- OrderSaga（Saga: 補償トランザクション付きオーケストレーション） ---
package OrderSaga {
    use Moo;

    has payment_service   => (is => 'ro', required => 1);
    has inventory_service => (is => 'ro', required => 1);
    has shipping_service  => (is => 'ro', required => 1);

    sub execute ($self, $order) {
        my @completed_steps;

        # Step 1: 決済
        my $payment = eval { $self->payment_service->charge($order->{amount}) };
        if ($@) {
            return { success => 0, error => "Payment failed: $@", step => 'payment' };
        }
        push @completed_steps, {
            name       => 'payment',
            compensate => sub { $self->payment_service->refund($payment->{id}) },
        };

        # Step 2: 在庫引当
        my $reservation = eval { $self->inventory_service->reserve($order->{item_id}, $order->{quantity}) };
        if ($@) {
            $self->_compensate(\@completed_steps);
            return { success => 0, error => "Inventory failed: $@", step => 'inventory' };
        }
        push @completed_steps, {
            name       => 'inventory',
            compensate => sub { $self->inventory_service->release($reservation->{id}) },
        };

        # Step 3: 配送手配
        my $shipment = eval { $self->shipping_service->schedule($order->{address}) };
        if ($@) {
            $self->_compensate(\@completed_steps);
            return { success => 0, error => "Shipping failed: $@", step => 'shipping' };
        }

        return {
            success     => 1,
            payment     => $payment,
            reservation => $reservation,
            shipment    => $shipment,
        };
    }

    sub _compensate ($self, $steps) {
        for my $step (reverse @$steps) {
            eval { $step->{compensate}->() };
            warn "Compensation failed for $step->{name}: $@" if $@;
        }
    }
}

1;

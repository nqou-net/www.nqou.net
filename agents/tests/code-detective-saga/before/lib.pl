use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

# === Before: No Compensation（補償なき分散処理） ===
# 複数ステップの処理を直列で実行するが、途中失敗時の巻き戻しロジックがない。
# 決済だけ成功して商品が届かない、という不整合が発生する。

# --- PaymentService（決済サービスのスタブ） ---
package PaymentService {
    use Moo;
    has charges => (is => 'rw', default => sub { [] });
    has should_fail => (is => 'rw', default => 0);

    sub charge ($self, $amount) {
        die "Payment declined\n" if $self->should_fail;
        my $payment = { id => 'PAY-' . (scalar @{ $self->charges } + 1), amount => $amount };
        push @{ $self->charges }, $payment;
        return $payment;
    }

    sub charge_count ($self) { scalar @{ $self->charges } }
}

# --- InventoryService（在庫サービスのスタブ） ---
package InventoryService {
    use Moo;
    has reservations => (is => 'rw', default => sub { [] });
    has should_fail  => (is => 'rw', default => 0);

    sub reserve ($self, $item_id, $quantity) {
        die "Out of stock\n" if $self->should_fail;
        my $reservation = { id => 'RES-' . (scalar @{ $self->reservations } + 1), item_id => $item_id, quantity => $quantity };
        push @{ $self->reservations }, $reservation;
        return $reservation;
    }

    sub reservation_count ($self) { scalar @{ $self->reservations } }
}

# --- ShippingService（配送サービスのスタブ） ---
package ShippingService {
    use Moo;
    has shipments   => (is => 'rw', default => sub { [] });
    has should_fail => (is => 'rw', default => 0);

    sub schedule ($self, $address) {
        die "Shipping unavailable\n" if $self->should_fail;
        my $shipment = { id => 'SHIP-' . (scalar @{ $self->shipments } + 1), address => $address };
        push @{ $self->shipments }, $shipment;
        return $shipment;
    }

    sub shipment_count ($self) { scalar @{ $self->shipments } }
}

# --- OrderProcessor（アンチパターン: 補償なしの直列処理） ---
package OrderProcessor {
    use Moo;

    has payment_service   => (is => 'ro', required => 1);
    has inventory_service => (is => 'ro', required => 1);
    has shipping_service  => (is => 'ro', required => 1);

    sub process_order ($self, $order) {
        # Step 1: 決済
        my $payment = $self->payment_service->charge($order->{amount});

        # Step 2: 在庫引当
        my $reservation = $self->inventory_service->reserve($order->{item_id}, $order->{quantity});

        # Step 3: 配送手配
        my $shipment = $self->shipping_service->schedule($order->{address});

        return { payment => $payment, reservation => $reservation, shipment => $shipment };
    }
}

1;

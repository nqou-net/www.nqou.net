package After::OrderFacade;
use v5.34;
use warnings;
use utf8;
use feature 'signatures';
no warnings "experimental::signatures";
use Moo;
use After::Subsystems;

# サブシステム群を保持する
has 'payment_svc' => (
    is => 'ro',
    default => sub { After::PaymentService->new },
);

has 'inventory_svc' => (
    is => 'ro',
    default => sub { After::InventoryService->new },
);

has 'shipping_svc' => (
    is => 'ro',
    default => sub { After::ShippingService->new },
);

has 'notification_svc' => (
    is => 'ro',
    default => sub { After::NotificationService->new },
);

# 単一のシンプルな窓口を提供する
sub place_order ($self, $item_id, $quantity, $email, $address, $amount) {
    say "=== Start Order Processing via Facade ===";

    # 1. 在庫の確保
    eval {
        $self->inventory_svc->reserve_item($item_id, $quantity);
    };
    if ($@) {
        warn "Failed to reserve item: $@";
        return 0;
    }

    # 2. 決済の処理
    eval {
        $self->payment_svc->process_payment($amount);
    };
    if ($@) {
        warn "Payment failed: $@";
        return 0;
    }

    # 3. 配送の手配
    eval {
        $self->shipping_svc->arrange_shipping($item_id, $address);
    };
    if ($@) {
        warn "Shipping arrangement failed: $@";
        return 0;
    }

    # 4. 領収書の送信
    eval {
        $self->notification_svc->send_receipt($email, $amount);
    };
    if ($@) {
        warn "Notification failed, but order proceeds: $@";
    }

    say "=== Order Processed Successfully via Facade ===";
    return 1;
}

1;

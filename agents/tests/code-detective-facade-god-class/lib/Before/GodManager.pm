package Before::GodManager;
use v5.34;
use warnings;
use utf8;
use feature 'signatures';
no warnings "experimental::signatures";
use Moo;
use Before::Subsystems;

# 神クラス（あるいは密結合の温床となるクラス）
# 全てのサブシステムのインスタンス化から呼び出し順序、エラーハンドリングまで
# すべてをここで直接制御しようとして、複雑怪奇になっている。

sub place_order ($self, $item_id, $quantity, $email, $address, $amount) {
    # 決済、在庫、配送、通知... 何でもかんでも知見を持っている
    my $payment_svc = Before::PaymentService->new;
    my $inventory_svc = Before::InventoryService->new;
    my $shipping_svc = Before::ShippingService->new;
    my $notification_svc = Before::NotificationService->new;

    say "=== Start Order Processing ===";

    # 1. 在庫の確保
    eval {
        $inventory_svc->reserve_item($item_id, $quantity);
    };
    if ($@) {
        warn "Failed to reserve item: $@";
        return 0;
    }

    # 2. 決済の処理
    eval {
        $payment_svc->process_payment($amount);
    };
    if ($@) {
        warn "Payment failed: $@";
        return 0;
    }

    # 3. 配送の手配
    eval {
        $shipping_svc->arrange_shipping($item_id, $address);
    };
    if ($@) {
        warn "Shipping arrangement failed: $@";
        return 0;
    }

    # 4. 領収書の送信
    eval {
        $notification_svc->send_receipt($email, $amount);
    };
    if ($@) {
        warn "Notification failed: $@";
        # 通知の失敗では注文自体はキャンセルしない（というような複雑なドメイン知識もここにある）
    }

    say "=== Order Processed Successfully ===";
    return 1;
}

1;

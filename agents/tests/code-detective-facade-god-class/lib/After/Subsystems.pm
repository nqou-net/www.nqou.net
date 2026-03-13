package After::Subsystems;
use v5.34;
use warnings;
use utf8;
use feature 'signatures';
no warnings "experimental::signatures";

# Facadeの裏側に隠れるサブシステム群（Beforeと同じクラスだが、モック処理のために複製）

package After::PaymentService {
    use Moo;
    sub process_payment ($self, $amount) {
        die "Invalid amount: $amount\n" if $amount <= 0;
        say "[PaymentService] Processed payment of $amount";
        return 1;
    }
}

package After::InventoryService {
    use Moo;
    sub reserve_item ($self, $item_id, $quantity) {
        say "[InventoryService] Reserved $quantity of item $item_id";
        return 1;
    }
}

package After::ShippingService {
    use Moo;
    sub arrange_shipping ($self, $item_id, $address) {
        say "[ShippingService] Arranged shipping for item $item_id to $address";
        return 1;
    }
}

package After::NotificationService {
    use Moo;
    sub send_receipt ($self, $email, $amount) {
        say "[NotificationService] Sent receipt ($amount) to $email";
        return 1;
    }
}

1;

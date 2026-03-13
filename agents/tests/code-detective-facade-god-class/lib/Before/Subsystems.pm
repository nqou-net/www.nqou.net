package Before::PaymentService;
use v5.34;
use warnings;
use utf8;
use feature 'signatures';
no warnings "experimental::signatures";
use Moo;

sub process_payment ($self, $amount) {
    if ($amount <= 0) {
        die "Invalid amount: $amount\n";
    }
    say "[PaymentService] Processed payment of $amount";
    return 1;
}

package Before::InventoryService;
use v5.34;
use warnings;
use utf8;
use feature 'signatures';
no warnings "experimental::signatures";
use Moo;

sub reserve_item ($self, $item_id, $quantity) {
    say "[InventoryService] Reserved $quantity of item $item_id";
    return 1;
}

package Before::ShippingService;
use v5.34;
use warnings;
use utf8;
use feature 'signatures';
no warnings "experimental::signatures";
use Moo;

sub arrange_shipping ($self, $item_id, $address) {
    say "[ShippingService] Arranged shipping for item $item_id to $address";
    return 1;
}

package Before::NotificationService;
use v5.34;
use warnings;
use utf8;
use feature 'signatures';
no warnings "experimental::signatures";
use Moo;

sub send_receipt ($self, $email, $amount) {
    say "[NotificationService] Sent receipt ($amount) to $email";
    return 1;
}

1;

use strict;
use warnings;
use Test::More;
use lib '.';
use Order;

subtest 'Order normal flow' => sub {
    my $order = Order->new;
    is $order->status, 'unpaid', 'Initial status is unpaid';
    
    is $order->process_payment, 'Payment processed successfully.', 'Payment processing';
    is $order->status, 'paid', 'Status changes to paid';
    
    is $order->ship_item, 'Item shipped successfully.', 'Shipping item';
    is $order->status, 'shipped', 'Status changes to shipped';
};

subtest 'Order cancellation' => sub {
    my $order = Order->new;
    $order->process_payment;
    is $order->cancel, 'Order cancelled.', 'Cancellation after payment';
    is $order->status, 'cancelled', 'Status changes to cancelled';
};

subtest 'Invalid transitions' => sub {
    my $order = Order->new;
    eval { $order->ship_item };
    like $@, qr/Cannot ship an unpaid order\./, 'Cannot ship unpaid';

    $order->process_payment;
    eval { $order->process_payment };
    like $@, qr/Order is already paid\./, 'Cannot pay twice';
};

done_testing;

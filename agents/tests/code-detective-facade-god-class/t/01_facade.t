use v5.34;
use warnings;
use utf8;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Before::GodManager;
use After::OrderFacade;

subtest 'Before: GodManager direct handling' => sub {
    my $manager = Before::GodManager->new;
    
    # 標準出力をキャプチャして動作確認（簡易的）
    my $output = "";
    open my $fh, '>', \$output;
    my $old_fh = select($fh);
    
    my $result = $manager->place_order(
        'ITEM-001', 
        2, 
        'test@example.com', 
        'Tokyo, Japan', 
        5000
    );
    
    select($old_fh);
    close $fh;
    
    ok($result, 'Order processed successfully');
    like($output, qr/=== Start Order Processing ===/, 'Starting log exists');
    like($output, qr/\[InventoryService\] Reserved 2 of item ITEM-001/, 'Inventory processed');
    like($output, qr/\[PaymentService\] Processed payment of 5000/, 'Payment processed');
    like($output, qr/\[ShippingService\] Arranged shipping for item ITEM-001 to Tokyo, Japan/, 'Shipping processed');
    like($output, qr/\[NotificationService\] Sent receipt \(5000\) to test\@example\.com/, 'Notification processed');
    like($output, qr/=== Order Processed Successfully ===/, 'Ending log exists');
};

subtest 'After: OrderFacade simplified handling' => sub {
    my $facade = After::OrderFacade->new;
    
    my $output = "";
    open my $fh, '>', \$output;
    my $old_fh = select($fh);
    
    # 呼び出し元（クライアント）は、$facadeの1つのメソッドを呼ぶだけで済む
    my $result = $facade->place_order(
        'ITEM-001', 
        2, 
        'test@example.com', 
        'Tokyo, Japan', 
        5000
    );
    
    select($old_fh);
    close $fh;
    
    ok($result, 'Order processed successfully via Facade');
    like($output, qr/=== Start Order Processing via Facade ===/, 'Starting log exists');
    like($output, qr/\[InventoryService\] Reserved 2 of item ITEM-001/, 'Inventory processed');
    like($output, qr/\[PaymentService\] Processed payment of 5000/, 'Payment processed');
    like($output, qr/\[ShippingService\] Arranged shipping for item ITEM-001 to Tokyo, Japan/, 'Shipping processed');
    like($output, qr/\[NotificationService\] Sent receipt \(5000\) to test\@example\.com/, 'Notification processed');
    like($output, qr/=== Order Processed Successfully via Facade ===/, 'Ending log exists');
};

done_testing();

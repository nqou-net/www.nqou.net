# InvoiceGenerator — OrderFacade を経由せず Order を直接使用
package InvoiceGenerator;
use v5.36;
use Moo;

has order => (
    is       => 'ro',
    required => 1,
);

sub generate ($self) {
    my $order = $self->order;
    my $shipping = do {
        my %rate = (kanto => 500, kansai => 700, other => 1000);
        $rate{$order->shipping_zone};
    };
    return sprintf(
        "請求書\n商品: %s x%d @%d = %d\n配送料: %d\n合計: %d",
        $order->item_name,
        $order->quantity,
        $order->unit_price,
        $order->total_price,
        $shipping,
        $order->total_price + $shipping,
    );
}

1;

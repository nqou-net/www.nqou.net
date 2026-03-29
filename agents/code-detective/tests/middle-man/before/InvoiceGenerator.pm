package InvoiceGenerator;
use v5.36;
use Moo;

# OrderFacade を経由して全情報を取得
has facade => (
    is       => 'ro',
    required => 1,
    handles  => [qw(
        item_name quantity unit_price total_price
        shipping_zone
    )],
);

sub generate ($self) {
    my $shipping = do {
        my %rate = (kanto => 500, kansai => 700, other => 1000);
        $rate{$self->shipping_zone};
    };
    return sprintf(
        "請求書\n商品: %s x%d @%d = %d\n配送料: %d\n合計: %d",
        $self->item_name,
        $self->quantity,
        $self->unit_price,
        $self->total_price,
        $shipping,
        $self->total_price + $shipping,
    );
}

1;

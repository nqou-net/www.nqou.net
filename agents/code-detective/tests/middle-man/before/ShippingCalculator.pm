package ShippingCalculator;
use v5.36;
use Moo;

# OrderFacade を経由して shipping_zone を取得
has facade => (
    is       => 'ro',
    required => 1,
    handles  => [qw(shipping_zone)],
);

sub calculate ($self) {
    my %rate = (kanto => 500, kansai => 700, other => 1000);
    return $rate{$self->shipping_zone};
}

1;

# ShippingCalculator — OrderFacade を経由せず Order を直接使用
package ShippingCalculator;
use v5.36;
use Moo;

has order => (
    is       => 'ro',
    required => 1,
    handles  => [qw(shipping_zone)],
);

sub calculate ($self) {
    my %rate = (kanto => 500, kansai => 700, other => 1000);
    return $rate{$self->shipping_zone};
}

1;

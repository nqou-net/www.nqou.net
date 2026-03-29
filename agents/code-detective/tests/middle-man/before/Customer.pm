package Customer;
use v5.36;
use Moo;

has name    => (is => 'ro', required => 1);
has email   => (is => 'ro', required => 1);
has address => (
    is       => 'ro',
    required => 1,
    handles  => [qw(shipping_zone)],
);

1;

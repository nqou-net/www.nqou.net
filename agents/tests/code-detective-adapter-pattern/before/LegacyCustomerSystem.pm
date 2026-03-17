package LegacyCustomerSystem;
use Moo;

sub fetch_customer_data {
    my ($self, $customer_id) = @_;
    return { customer_id => $customer_id, full_name => "Customer $customer_id", mail_address => "customer${customer_id}\@legacy.local" };
}

1;

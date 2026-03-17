package LegacyCustomerAdapter;
use Moo;

has legacy_system => (
    is       => 'ro',
    required => 1,
);

# Adapter implements the same interface as UserService
sub get_user_info {
    my ($self, $id) = @_;
    
    # Delegate to the adaptee
    my $raw_data = $self->legacy_system->fetch_customer_data($id);
    
    # Translate the interface
    return {
        id    => $raw_data->{customer_id},
        name  => $raw_data->{full_name},
        email => $raw_data->{mail_address},
    };
}

1;

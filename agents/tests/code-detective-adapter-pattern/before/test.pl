use strict;
use warnings;
use Test::More;
use lib '.';
use UserService;
use LegacyCustomerSystem;

# Client code with Incompatible Interfaces Anti-pattern
sub get_normalized_user {
    my ($system_type, $id, $system_instance) = @_;
    
    if ($system_type eq 'new') {
        return $system_instance->get_user_info($id);
    } elsif ($system_type eq 'legacy') {
        # The Anti-Pattern: Hardcoded conversion and branching
        my $raw_data = $system_instance->fetch_customer_data($id);
        return {
            id    => $raw_data->{customer_id},
            name  => $raw_data->{full_name},
            email => $raw_data->{mail_address},
        };
    }
    die "Unknown system type: $system_type";
}

my $new_system = UserService->new();
my $legacy_system = LegacyCustomerSystem->new();

my $user1 = get_normalized_user('new', 1, $new_system);
is($user1->{name}, 'User 1', 'New system User 1');
is($user1->{email}, 'user1@example.com', 'New system User 1 email');

my $user2 = get_normalized_user('legacy', 2, $legacy_system);
is($user2->{name}, 'Customer 2', 'Legacy system Customer 2');
is($user2->{email}, 'customer2@legacy.local', 'Legacy system Customer 2 email');

done_testing;

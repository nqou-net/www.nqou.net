use strict;
use warnings;
use Test::More;
use lib '.';
use UserService;
use LegacyCustomerSystem;
use LegacyCustomerAdapter;

# Client code expecting objects with a get_user_info method
sub fetch_data {
    my ($service, $id) = @_;
    return $service->get_user_info($id);
}

my $new_system = UserService->new();
my $legacy_system = LegacyCustomerSystem->new();

# Wrap the legacy system with the adapter
my $adapter = LegacyCustomerAdapter->new(legacy_system => $legacy_system);

# Now both can be treated exactly the same way
my $user1 = fetch_data($new_system, 1);
is($user1->{name}, 'User 1', 'New system User 1');
is($user1->{email}, 'user1@example.com', 'New system User 1 email');

my $user2 = fetch_data($adapter, 2);
is($user2->{name}, 'Customer 2', 'Legacy system Customer 2 through adapter');
is($user2->{email}, 'customer2@legacy.local', 'Legacy system Customer 2 email through adapter');

done_testing;

#!/usr/bin/env perl
use v5.36;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

require '02_tell_dont_ask_solution.pl';

my $service = OrderService->new;

# Normal user
my $order1 = Order->new(amount => 5000, user_type => 'normal');
is($service->process_order($order1), 5000, 'Normal user: no discount');

# Premium user, low amount (< 10000)
my $order2 = Order->new(amount => 5000, user_type => 'premium');
is($service->process_order($order2), 4750, 'Premium user (<10000): 5% discount');

# Premium user, high amount (>= 10000)
my $order3 = Order->new(amount => 10000, user_type => 'premium');
is($service->process_order($order3), 8500, 'Premium user (>=10000): 15% discount');

done_testing;

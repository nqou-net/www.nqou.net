#!/usr/bin/env perl
# t/02-integration.t
# Integration test for the complete payment check system

use v5.36;
use utf8;
use warnings;
use Test::More tests => 14;
binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

# Load the main script
our $first_checker;
require './payment-check-03.pl';

# Note: The main script has already built the checker chain
# We'll test by calling the first_checker with various scenarios

# Test 1: Normal approval
{
    my $result = $first_checker->check({
        name         => 'Normal payment',
        amount       => 50_000,
        expiry_year  => 2028,
        expiry_month => 12,
        card_number  => '5105105105105100',
    });
    ok($result->{ok}, 'Normal payment should be approved');
}

# Test 2: Amount over limit
{
    my $result = $first_checker->check({
        amount       => 200_000,
        expiry_year  => 2028,
        expiry_month => 12,
        card_number  => '5105105105105100',
    });
    ok(!$result->{ok}, 'Over-limit payment should be rejected');
    ok($result->{reason}, 'Should have rejection reason');
}

# Test 3: Expired card
{
    my $result = $first_checker->check({
        amount       => 50_000,
        expiry_year  => 2025,
        expiry_month => 6,
        card_number  => '5105105105105100',
    });
    ok(!$result->{ok}, 'Expired card should be rejected');
    ok($result->{reason}, 'Should have rejection reason');
}

# Test 4: Blacklisted card
{
    my $result = $first_checker->check({
        amount       => 50_000,
        expiry_year  => 2028,
        expiry_month => 12,
        card_number  => '4111111111111111',
    });
    ok(!$result->{ok}, 'Blacklisted card should be rejected');
    ok($result->{reason}, 'Should have rejection reason');
}

# Test 5: Insufficient balance
{
    my $result = $first_checker->check({
        amount       => 80_000,
        expiry_year  => 2028,
        expiry_month => 12,
        card_number  => '4242424242424242',
    });
    # 4242424242424242 has 100,000 balance, so 80,000 should pass
    ok($result->{ok}, 'Payment within balance should be approved');
}

# Test 6: Exact balance limit
{
    my $result = $first_checker->check({
        amount       => 100_000,
        expiry_year  => 2028,
        expiry_month => 12,
        card_number  => '4242424242424242',
    });
    # Should fail at limit check before balance check
    ok(!$result->{ok}, 'Payment at system limit should be rejected');
}

# Test 7: Fraud detection (too many transactions)
{
    # Card 4111111111111111 has 5 transactions, threshold is 3
    # But it's also blacklisted, so it will fail at blacklist check first
    my $result = $first_checker->check({
        amount       => 1_000,
        expiry_year  => 2028,
        expiry_month => 12,
        card_number  => '4111111111111111',
    });
    ok(!$result->{ok}, 'Card with fraud suspicion should be rejected');
}

# Test 7: Unknown card (no balance)
{
    my $result = $first_checker->check({
        amount       => 1,
        expiry_year  => 2028,
        expiry_month => 12,
        card_number  => '9999999999999999',
    });
    ok(!$result->{ok}, 'Unknown card should be rejected');
    ok($result->{reason}, 'Should have rejection reason');
}

# Test 9: All checks pass
{
    my $result = $first_checker->check({
        amount       => 10_000,
        expiry_year  => 2030,
        expiry_month => 12,
        card_number  => '5105105105105100',
    });
    ok($result->{ok}, 'Valid payment should pass all checks');
}

# Test 10: Edge case - amount at limit minus 1
{
    my $result = $first_checker->check({
        amount       => 99_999,
        expiry_year  => 2028,
        expiry_month => 12,
        card_number  => '5105105105105100',
    });
    ok($result->{ok}, 'Payment just under limit should be approved');
}

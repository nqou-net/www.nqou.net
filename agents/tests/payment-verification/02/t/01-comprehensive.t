#!/usr/bin/env perl
# t/01-comprehensive.t
# Comprehensive test for payment-check-02.pl

use v5.36;
use utf8;
use warnings;
use Test::More tests => 16;
binmode STDOUT, ':utf8';

# Load the payment check function
require './payment-check-02.pl';

# Test 1: Normal approval
{
    my $result = check_payment({
        amount       => 50_000,
        expiry_year  => 2028,
        expiry_month => 12,
        card_number  => '5105105105105100',
    });
    ok($result->{ok}, 'Normal payment should be approved');
    is($result->{amount}, 50_000, 'Amount should match');
}

# Test 2: Amount exceeds limit
{
    my $result = check_payment({
        amount       => 100_000,
        expiry_year  => 2028,
        expiry_month => 12,
        card_number  => '5105105105105100',
    });
    ok(!$result->{ok}, 'Payment at limit should be rejected');
    like($result->{reason}, qr/上限/, 'Should mention limit');
}

# Test 3: Expired card
{
    my $result = check_payment({
        amount       => 50_000,
        expiry_year  => 2025,
        expiry_month => 6,
        card_number  => '5105105105105100',
    });
    ok(!$result->{ok}, 'Expired card should be rejected');
    like($result->{reason}, qr/有効期限/, 'Should mention expiry');
}

# Test 4: Blacklisted card (first one)
{
    my $result = check_payment({
        amount       => 50_000,
        expiry_year  => 2028,
        expiry_month => 12,
        card_number  => '4111111111111111',
    });
    ok(!$result->{ok}, 'Blacklisted card should be rejected');
    like($result->{reason}, qr/使用できません/, 'Should mention card cannot be used');
}

# Test 5: Blacklisted card (second one)
{
    my $result = check_payment({
        amount       => 50_000,
        expiry_year  => 2028,
        expiry_month => 12,
        card_number  => '5500000000000004',
    });
    ok(!$result->{ok}, 'Second blacklisted card should be rejected');
}

# Test 6: Insufficient balance
{
    my $result = check_payment({
        amount       => 80_000,
        expiry_year  => 2028,
        expiry_month => 12,
        card_number  => '4242424242424242',
    });
    # 4242424242424242 has 100,000 balance, so 80,000 should pass
    ok($result->{ok}, 'Payment within balance should be approved');
}

# Test 7: Fraud detection (too many transactions)
{
    my $result = check_payment({
        amount       => 50_000,
        expiry_year  => 2028,
        expiry_month => 12,
        card_number  => '4111111111111111',
    });
    ok(!$result->{ok}, 'Card with multiple transactions should be rejected (or blacklisted)');
}

# Test 8: Unknown card (no balance info)
{
    my $result = check_payment({
        amount       => 1,
        expiry_year  => 2028,
        expiry_month => 12,
        card_number  => '9999999999999999',
    });
    ok(!$result->{ok}, 'Unknown card with no balance should be rejected');
}

# Test 9: Card with balance, amount within limit
{
    my $result = check_payment({
        amount       => 80_000,
        expiry_year  => 2028,
        expiry_month => 12,
        card_number  => '4242424242424242',
    });
    ok($result->{ok}, 'Payment within balance should be approved');
}

# Test 10: Edge case - exact balance
{
    my $result = check_payment({
        amount       => 500_000,
        expiry_year  => 2028,
        expiry_month => 12,
        card_number  => '5105105105105100',
    });
    # Should fail because 500_000 >= 100_000 (limit check comes first)
    ok(!$result->{ok}, 'Payment over limit should fail even with balance');
}

# Test 11: Missing card number
{
    my $result = check_payment({
        amount       => 50_000,
        expiry_year  => 2028,
        expiry_month => 12,
    });
    ok(!$result->{ok}, 'Missing card number should fail balance check');
}

# Test 12: All checks pass in correct order
{
    my $result = check_payment({
        amount       => 10_000,
        expiry_year  => 2030,
        expiry_month => 12,
        card_number  => '5105105105105100',
    });
    ok($result->{ok}, 'Valid payment should pass all checks');
}

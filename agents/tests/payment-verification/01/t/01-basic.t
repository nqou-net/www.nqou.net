#!/usr/bin/env perl
# t/01-basic.t
# Test for payment-check-01.pl

use v5.36;
use utf8;
use warnings;
use Test::More tests => 12;
binmode STDOUT, ':utf8';

# Load the payment check function
require './payment-check-01.pl';

# Test 1: Normal approval (valid amount and expiry)
{
    my $result = check_payment({
        amount       => 50_000,
        expiry_year  => 2028,
        expiry_month => 12,
    });
    ok($result->{ok}, 'Normal payment should be approved');
    is($result->{amount}, 50_000, 'Amount should match');
}

# Test 2: Amount at limit (99,999 should pass)
{
    my $result = check_payment({
        amount       => 99_999,
        expiry_year  => 2028,
        expiry_month => 12,
    });
    ok($result->{ok}, 'Payment just under limit should be approved');
}

# Test 3: Amount exceeds limit
{
    my $result = check_payment({
        amount       => 100_000,
        expiry_year  => 2028,
        expiry_month => 12,
    });
    ok(!$result->{ok}, 'Payment at limit should be rejected');
    like($result->{reason}, qr/上限/, 'Should have amount limit message');
}

# Test 4: Expired card (year in past)
{
    my $result = check_payment({
        amount       => 50_000,
        expiry_year  => 2023,
        expiry_month => 12,
    });
    ok(!$result->{ok}, 'Expired card should be rejected');
    like($result->{reason}, qr/有効期限/, 'Should have expiry message');
}

# Test 5: Expired card (same year, past month)
{
    my $result = check_payment({
        amount       => 50_000,
        expiry_year  => 2025,
        expiry_month => 6,
    });
    ok(!$result->{ok}, 'Card expired this year should be rejected');
    like($result->{reason}, qr/有効期限/, 'Should have expiry message');
}

# Test 6: Default values (missing data)
{
    my $result = check_payment({});
    ok(!$result->{ok}, 'Missing data should be rejected');
}

# Test 7: Zero amount
{
    my $result = check_payment({
        amount       => 0,
        expiry_year  => 2028,
        expiry_month => 12,
    });
    ok($result->{ok}, 'Zero amount should be approved');
}

# Test 8: Large amount over limit
{
    my $result = check_payment({
        amount       => 1_000_000,
        expiry_year  => 2028,
        expiry_month => 12,
    });
    ok(!$result->{ok}, 'Very large amount should be rejected');
}

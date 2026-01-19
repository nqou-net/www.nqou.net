#!/usr/bin/env perl
# t/01-modules.t
# Test individual checker modules

use v5.36;
use utf8;
use warnings;
use Test::More tests => 29;
use lib 'lib';

binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

# Test PaymentChecker base class
{
    use_ok('PaymentChecker');
    my $checker = PaymentChecker->new;
    isa_ok($checker, 'PaymentChecker');
    
    # Test default behavior (pass through)
    my $result = $checker->check({ amount => 1000 });
    ok($result->{ok}, 'Base checker passes by default');
    
    # Test chaining
    my $next = PaymentChecker->new;
    $checker->set_next($next);
    ok($checker->has_next_handler, 'Next handler is set');
}

# Test LimitChecker
{
    use_ok('LimitChecker');
    my $checker = LimitChecker->new;
    isa_ok($checker, 'LimitChecker');
    isa_ok($checker, 'PaymentChecker');
    
    # Test default limit
    is($checker->limit, 100_000, 'Default limit is 100,000');
    
    # Test under limit
    my $result = $checker->check({ amount => 50_000 });
    ok($result->{ok}, 'Amount under limit passes');
    
    # Test at limit
    $result = $checker->check({ amount => 100_000 });
    ok(!$result->{ok}, 'Amount at limit fails');
    ok($result->{reason}, 'Has reason for rejection');
    
    # Test custom limit
    my $custom = LimitChecker->new(limit => 50_000);
    is($custom->limit, 50_000, 'Custom limit is set');
}

# Test ExpiryChecker
{
    use_ok('ExpiryChecker');
    my $checker = ExpiryChecker->new;
    isa_ok($checker, 'ExpiryChecker');
    isa_ok($checker, 'PaymentChecker');
    
    # Test valid expiry
    my $result = $checker->check({
        expiry_year  => 2030,
        expiry_month => 12,
    });
    ok($result->{ok}, 'Future date passes');
    
    # Test expired (past year)
    $result = $checker->check({
        expiry_year  => 2020,
        expiry_month => 12,
    });
    ok(!$result->{ok}, 'Past year fails');
    ok($result->{reason}, 'Has reason for rejection');
    
    # Test expired (past month, current year)
    $result = $checker->check({
        expiry_year  => 2025,
        expiry_month => 1,
    });
    ok(!$result->{ok}, 'Past month in 2025 fails');
}

# Test BlacklistChecker
{
    use_ok('BlacklistChecker');
    my $checker = BlacklistChecker->new(
        blacklist => ['1111', '2222'],
    );
    isa_ok($checker, 'BlacklistChecker');
    isa_ok($checker, 'PaymentChecker');
    
    # Test not blacklisted
    my $result = $checker->check({ card_number => '3333' });
    ok($result->{ok}, 'Non-blacklisted card passes');
    
    # Test blacklisted
    $result = $checker->check({ card_number => '1111' });
    ok(!$result->{ok}, 'Blacklisted card fails');
    ok($result->{reason}, 'Has reason for rejection');
    
    # Test empty blacklist
    my $empty = BlacklistChecker->new;
    $result = $empty->check({ card_number => '1111' });
    ok($result->{ok}, 'Empty blacklist passes all');
}

# Test chaining
{
    my $limit = LimitChecker->new(limit => 100_000);
    my $expiry = ExpiryChecker->new;
    my $blacklist = BlacklistChecker->new(blacklist => ['4111111111111111']);
    
    $limit->set_next($expiry)->set_next($blacklist);
    
    # Test: passes all checks
    my $result = $limit->check({
        amount       => 50_000,
        expiry_year  => 2030,
        expiry_month => 12,
        card_number  => '5105105105105100',
    });
    ok($result->{ok}, 'Valid request passes chain');
    
    # Test: fails at first check (limit)
    $result = $limit->check({
        amount       => 200_000,
        expiry_year  => 2030,
        expiry_month => 12,
        card_number  => '5105105105105100',
    });
    ok(!$result->{ok}, 'Overlimit fails at first check');
    
    # Test: fails at second check (expiry)
    $result = $limit->check({
        amount       => 50_000,
        expiry_year  => 2020,
        expiry_month => 12,
        card_number  => '5105105105105100',
    });
    ok(!$result->{ok}, 'Expired fails at second check');
}

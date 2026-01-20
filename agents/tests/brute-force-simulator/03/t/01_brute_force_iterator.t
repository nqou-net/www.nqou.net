use v5.36;
use Test::More;
use lib 'lib';

use_ok('BruteForceIterator');

subtest 'BruteForceIterator basic tests' => sub {
    my $iter = BruteForceIterator->new(length => 2);
    isa_ok($iter, 'BruteForceIterator');
    
    is($iter->next, '00', 'First value is 00');
    is($iter->next, '01', 'Second value is 01');
    is($iter->next, '02', 'Third value is 02');
};

subtest 'BruteForceIterator exhaustion' => sub {
    my $iter = BruteForceIterator->new(length => 1);
    
    my @values;
    while (defined(my $val = $iter->next)) {
        push @values, $val;
    }
    
    is(scalar @values, 10, 'Generates 10 values for length 1');
    is($values[0], '0', 'First value is 0');
    is($values[9], '9', 'Last value is 9');
    
    is($iter->next, undef, 'Returns undef when exhausted');
};

subtest 'BruteForceIterator formatting' => sub {
    my $iter = BruteForceIterator->new(length => 3);
    
    is($iter->next, '000', 'Zero-padded to 3 digits');
    
    # Skip to near the end
    for (1 .. 998) { $iter->next; }
    
    is($iter->next, '999', 'Last value is 999');
    is($iter->next, undef, 'Returns undef after last value');
};

done_testing();

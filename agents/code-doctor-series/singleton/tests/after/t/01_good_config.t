use v5.36;
use Test2::V0;
use Test::More;

use lib 'agents/code-doctor-series/singleton/tests/after/lib';
use Good::Config;

subtest 'Good Code: Singleton (Cure)' => sub {
    my $config1 = Good::Config->new;

    # Simulate time passing to see if reloaded
    sleep 1;

    my $config2 = Good::Config->new;

    # 全く同じインスタンスである（参照が一致）
    is $config1, $config2, 'References should be identical';

    # データも当然同じ
    is $config1->{loaded_at}, $config2->{loaded_at}, 'Loaded timestamps should be identical (Single Source of Truth)';
};

done_testing;

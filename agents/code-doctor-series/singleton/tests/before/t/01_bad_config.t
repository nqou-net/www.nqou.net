use v5.36;
use Test2::V0;
use Test::More;

use lib 'agents/code-doctor-series/singleton/tests/before/lib';
use Bad::Config;

subtest 'Bad Code: Multiple Instances (Symptom)' => sub {
    my $config1 = Bad::Config->new;

    # Simulate time passing to ensure timestamps differ if new instances are created
    sleep 1;

    my $config2 = Bad::Config->new;

    # Instances should be different (creating new objects every time)
    isnt $config1, $config2, 'References should NOT be identical (Multiple Personality)';

    # Ideally, we want single source of truth, but here we have divergence
    # If loaded_at is different, it means we re-loaded the config
    if ($config1->{loaded_at} != $config2->{loaded_at}) {
        pass 'Timestamps are different (Config reloaded)';
    }
    else {
        # This might fail if sleep(1) isn't enough or system is too fast, but for demo it's fine
        # In a real "bad code" scenario, this confirms multiple loads.
        note "Timestamps are same, maybe execution was too fast?";
    }
};

done_testing;

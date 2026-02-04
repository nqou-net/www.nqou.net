use v5.36;
use Test2::V0;
use lib 'lib';

use Bad::Config;
use Good::Config;

subtest 'Bad Code: Multiple Instances (Symptom)' => sub {
    my $config1 = Bad::Config->new;
    sleep 1;    # timestampをずらす
    my $config2 = Bad::Config->new;

    # 別々のインスタンスである
    isnt $config1, $config2, 'References should be different';

    # 読み込み時刻も違う（無駄な再読み込み）
    isnt $config1->{loaded_at}, $config2->{loaded_at}, 'Loaded timestamps should be different';
};

subtest 'Good Code: Singleton (Cure)' => sub {
    my $config1 = Good::Config->new;
    my $config2 = Good::Config->new;

    # 全く同じインスタンスである（参照が一致）
    is $config1, $config2, 'References should be identical';

    # データも当然同じ
    is $config1->{loaded_at}, $config2->{loaded_at}, 'Loaded timestamps should be identical';
};

done_testing;

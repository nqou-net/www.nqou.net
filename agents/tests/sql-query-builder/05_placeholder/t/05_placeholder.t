use v5.36;
use Test::More;
use lib 'lib';
use_ok 'QueryBuilder';

subtest 'Secure query with placeholders' => sub {
    my $builder = QueryBuilder->new
        ->from('users')
        ->where('name', "John ' OR '1'='1");
        
    is $builder->build, "SELECT * FROM users WHERE name = ?", 'SQL contains placeholder';
    is_deeply [$builder->bind_values], ["John ' OR '1'='1"], 'Value is stored separately';
};

done_testing;

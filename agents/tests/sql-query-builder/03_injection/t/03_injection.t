use v5.36;
use Test::More;
use lib 'lib';
use_ok 'Query';

subtest 'Demonstrate SQL Injection' => sub {
    my $query = Query->new(
        table        => 'users',
        where_column => 'name',
        where_value  => "' OR '1'='1",
    );
    
    my $sql = $query->to_sql;
    note "Generated SQL: $sql";
    
    # 攻撃が成功してしまうことを確認（WHERE句が意図せず成立する）
    like $sql, qr/name = '' OR '1'='1'/, 'Vulnerable SQL generated';
};

done_testing;

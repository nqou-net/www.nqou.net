use v5.36;
use Test::More;
use lib 'lib';

use_ok 'Query';

# パラメータ地獄のテスト
my $query = Query->new(
    table        => 'users',
    where_column => 'status',
    where_value  => 'active',
    order_column => 'created_at',
    order_dir    => 'DESC',
    limit_count  => 10,
    offset_count => 20,
);

is $query->to_sql, 
   "SELECT * FROM users WHERE status = 'active' ORDER BY created_at DESC LIMIT 10 OFFSET 20",
   'Complex query via telescoping constructor';

done_testing;

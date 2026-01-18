use v5.36;
use Test::More;
use lib 'lib';
use_ok 'QueryBuilder';

subtest 'Complex query construction' => sub {
    my $builder = QueryBuilder->new
        ->select('users.*', 'COUNT(orders.id)')
        ->from('users')
        ->left_join('orders', 'users.id', 'orders.user_id')
        ->where('users.status', 'active')
        ->group_by('users.id')
        ->having('COUNT(orders.id)', '>', 5)
        ->order_by('users.created_at', 'DESC')
        ->limit(20)
        ->offset(0);
        
    my $sql = $builder->build;
    
    like $sql, qr/SELECT users\.\*, COUNT\(orders\.id\) FROM users/;
    like $sql, qr/LEFT JOIN orders ON users\.id = orders\.user_id/;
    like $sql, qr/WHERE users\.status = \?/;
    like $sql, qr/GROUP BY users\.id/;
    like $sql, qr/HAVING COUNT\(orders\.id\) > \?/;
    like $sql, qr/ORDER BY users\.created_at DESC/;
    like $sql, qr/LIMIT 20/;
    
    is_deeply [$builder->bind_values], ['active', 5];
};

done_testing;

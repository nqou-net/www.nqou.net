use v5.36;
use Test::More;
use lib 'lib';
use_ok 'QueryDirector';

my $director = QueryDirector->new;

subtest 'QueryDirector generates valid queries' => sub {
    # ページネーション付き検索
    my $builder = $director->build_paginated_search(
        table    => 'users',
        filters  => { status => 'active' },
        order_by => 'created_at',
        order    => 'DESC',
        page     => 2,
        per_page => 30,
    );
    
    my $sql = $builder->build;
    like $sql, qr/SELECT \* FROM users/;
    like $sql, qr/WHERE status = \?/;
    like $sql, qr/ORDER BY created_at DESC/;
    like $sql, qr/LIMIT 30 OFFSET 30/;
    
    # ユーザー集計
    my $agg_builder = $director->build_user_aggregate(
        table      => 'orders',
        sum_column => 'total',
        min_total  => 5000,
    );
    
    my $agg_sql = $agg_builder->build;
    like $agg_sql, qr/SELECT user_id, COUNT\(\*\) as count, SUM\(total\) as total/;
    like $agg_sql, qr/GROUP BY user_id/;
    like $agg_sql, qr/HAVING SUM\(total\) > \?/;
};

done_testing;

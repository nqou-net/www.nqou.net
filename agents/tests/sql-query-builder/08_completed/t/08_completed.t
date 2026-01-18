#!/usr/bin/env perl
# 全記事のコード動作確認テスト
use v5.36;
use Test::More;
use Test::Exception;
use lib 'lib';

# === 第1回: シンプルなQuery ===
subtest 'Article 1: Simple Query' => sub {
    use_ok('Query');
    
    my $query = Query->new(table => 'users');
    is $query->to_sql, 'SELECT * FROM users', 'Simple SELECT query';
};

# === 第4回〜第8回: QueryBuilder ===
subtest 'Article 4-8: QueryBuilder' => sub {
    use_ok('QueryBuilder');
    
    # 基本的なSELECT
    subtest 'Simple SELECT' => sub {
        my $builder = QueryBuilder->new->from('users');
        is $builder->build, 'SELECT * FROM users';
    };
    
    # カラム指定
    subtest 'SELECT with columns' => sub {
        my $builder = QueryBuilder->new
            ->select('id', 'name')
            ->from('users');
        is $builder->build, 'SELECT id, name FROM users';
    };
    
    # WHERE句
    subtest 'WHERE clause' => sub {
        my $builder = QueryBuilder->new
            ->from('users')
            ->where('status', 'active');
        
        is $builder->build, 'SELECT * FROM users WHERE status = ?';
        is_deeply [$builder->bind_values], ['active'];
    };
    
    # 複数WHERE条件
    subtest 'Multiple WHERE conditions' => sub {
        my $builder = QueryBuilder->new
            ->from('users')
            ->where('status', 'active')
            ->where('role', 'admin');
        
        is $builder->build, 'SELECT * FROM users WHERE status = ? AND role = ?';
        is_deeply [$builder->bind_values], ['active', 'admin'];
    };
    
    # JOIN句
    subtest 'JOIN clause' => sub {
        my $builder = QueryBuilder->new
            ->from('users')
            ->join('orders', 'users.id', 'orders.user_id');
        
        like $builder->build, qr/INNER JOIN orders ON users\.id = orders\.user_id/;
    };
    
    # LEFT JOIN句
    subtest 'LEFT JOIN clause' => sub {
        my $builder = QueryBuilder->new
            ->from('users')
            ->left_join('orders', 'users.id', 'orders.user_id');
        
        like $builder->build, qr/LEFT JOIN orders ON users\.id = orders\.user_id/;
    };
    
    # ORDER BY
    subtest 'ORDER BY' => sub {
        my $builder = QueryBuilder->new
            ->from('users')
            ->order_by('created_at', 'DESC');
        
        like $builder->build, qr/ORDER BY created_at DESC/;
    };
    
    # LIMIT and OFFSET
    subtest 'LIMIT and OFFSET' => sub {
        my $builder = QueryBuilder->new
            ->from('users')
            ->limit(10)
            ->offset(20);
        
        like $builder->build, qr/LIMIT 10 OFFSET 20/;
    };
    
    # GROUP BY and HAVING
    subtest 'GROUP BY and HAVING' => sub {
        my $builder = QueryBuilder->new
            ->select('user_id', 'COUNT(*)')
            ->from('orders')
            ->group_by('user_id')
            ->having('COUNT(*)', '>', 5);
        
        like $builder->build, qr/GROUP BY user_id HAVING COUNT\(\*\) > \?/;
        is_deeply [$builder->bind_values], [5];
    };
    
    # バリデーション: テーブル必須
    subtest 'Validation: table required' => sub {
        my $builder = QueryBuilder->new;
        throws_ok { $builder->build } qr/Table not specified/;
    };
    
    # バリデーション: 不正なORDER方向
    subtest 'Validation: invalid order direction' => sub {
        my $builder = QueryBuilder->new->from('users');
        throws_ok { $builder->order_by('id', 'INVALID') } qr/Invalid order direction/;
    };
    
    # バリデーション: OFFSETはLIMIT必須
    subtest 'Validation: offset requires limit' => sub {
        my $builder = QueryBuilder->new->from('users');
        throws_ok { $builder->offset(10) } qr/Offset requires LIMIT/;
    };
    
    # リセット機能
    subtest 'Reset builder' => sub {
        my $builder = QueryBuilder->new
            ->from('users')
            ->where('status', 'active');
        
        $builder->reset;
        throws_ok { $builder->build } qr/Table not specified/;
    };
};

# === 第7回: QueryDirector ===
subtest 'Article 7: QueryDirector' => sub {
    use_ok('QueryDirector');
    
    my $director = QueryDirector->new;
    
    # ページネーション付き検索
    subtest 'Paginated search' => sub {
        my $builder = $director->build_paginated_search(
            table    => 'users',
            filters  => { status => 'active' },
            order_by => 'created_at',
            order    => 'DESC',
            page     => 3,
            per_page => 25,
        );
        
        my $sql = $builder->build;
        like $sql, qr/FROM users/;
        like $sql, qr/WHERE status = \?/;
        like $sql, qr/ORDER BY created_at DESC/;
        like $sql, qr/LIMIT 25 OFFSET 50/;
    };
    
    # 集計レポート
    subtest 'User aggregate' => sub {
        my $builder = $director->build_user_aggregate(
            table      => 'orders',
            sum_column => 'total',
            min_total  => 10000,
        );
        
        my $sql = $builder->build;
        like $sql, qr/SELECT user_id, COUNT\(\*\) as count, SUM\(total\) as total/;
        like $sql, qr/GROUP BY user_id/;
        like $sql, qr/HAVING SUM\(total\) > \?/;
    };
    
    # ユーザーと注文
    subtest 'User with orders' => sub {
        my $builder = $director->build_user_with_orders(
            user_id => 42,
            status  => 'completed',
        );
        
        my $sql = $builder->build;
        like $sql, qr/LEFT JOIN orders/;
        like $sql, qr/WHERE users\.id = \?/;
    };
};

done_testing;

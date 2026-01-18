# QueryDirector.pm - 第7回: Director
package QueryDirector;
use v5.36;
use Moo;
use QueryBuilder;

sub build_paginated_search ($self, %opts) {
    my $table    = $opts{table};
    my $filters  = $opts{filters} // {};
    my $order_by = $opts{order_by} // 'id';
    my $order    = $opts{order} // 'ASC';
    my $page     = $opts{page} // 1;
    my $per_page = $opts{per_page} // 20;
    
    my $builder = QueryBuilder->new->from($table);
    
    for my $column (keys $filters->%*) {
        $builder->where($column, $filters->{$column});
    }
    
    $builder->order_by($order_by, $order)
            ->limit($per_page)
            ->offset(($page - 1) * $per_page);
    
    return $builder;
}

sub build_user_aggregate ($self, %opts) {
    my $table      = $opts{table};
    my $sum_column = $opts{sum_column};
    my $min_total  = $opts{min_total} // 0;
    
    my $builder = QueryBuilder->new
        ->select('user_id', "COUNT(*) as count", "SUM($sum_column) as total")
        ->from($table)
        ->group_by('user_id');
    
    if ($min_total > 0) {
        $builder->having("SUM($sum_column)", '>', $min_total);
    }
    
    $builder->order_by('total', 'DESC');
    
    return $builder;
}

sub build_user_with_orders ($self, %opts) {
    my $user_id = $opts{user_id};
    my $status  = $opts{status};
    
    my $builder = QueryBuilder->new
        ->select('users.id', 'users.name', 'orders.id as order_id', 'orders.total')
        ->from('users')
        ->left_join('orders', 'users.id', 'orders.user_id')
        ->where('users.id', $user_id);
    
    if ($status) {
        $builder->where('orders.status', $status);
    }
    
    $builder->order_by('orders.created_at', 'DESC');
    
    return $builder;
}

sub build_recent_active_users ($self, %opts) {
    my $days  = $opts{days} // 7;
    my $limit = $opts{limit} // 100;
    
    return QueryBuilder->new
        ->select('users.*', 'COUNT(orders.id) as order_count')
        ->from('users')
        ->join('orders', 'users.id', 'orders.user_id')
        ->group_by('users.id')
        ->having('COUNT(orders.id)', '>', 0)
        ->order_by('order_count', 'DESC')
        ->limit($limit);
}

1;

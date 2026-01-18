package QueryBuilder;
use v5.36;
use Moo;

has _table      => (is => 'rw');
has _columns    => (is => 'rw', default => sub { [] });
has _conditions => (is => 'rw', default => sub { [] });
has _orders     => (is => 'rw', default => sub { [] });
has _limit      => (is => 'rw');

# テーブル指定
sub from ($self, $table) {
    $self->_table($table);
    return $self;  # メソッドチェーンのためにselfを返す
}

# カラム指定（省略時は*）
sub select ($self, @columns) {
    push $self->_columns->@*, @columns;
    return $self;
}

# WHERE条件
sub where ($self, $column, $value) {
    push $self->_conditions->@*, { column => $column, value => $value };
    return $self;
}

# ORDER BY
sub order_by ($self, $column, $dir = 'ASC') {
    push $self->_orders->@*, { column => $column, dir => $dir };
    return $self;
}

# LIMIT
sub limit ($self, $count) {
    $self->_limit($count);
    return $self;
}

# SQLを生成
sub build ($self) {
    my @columns = $self->_columns->@*;
    my $cols = @columns ? CORE::join(', ', @columns) : '*';
    
    my $sql = "SELECT $cols FROM " . $self->_table;
    
    if ($self->_conditions->@*) {
        my @wheres;
        for my $cond ($self->_conditions->@*) {
            push @wheres, "$cond->{column} = '$cond->{value}'";
        }
        $sql .= " WHERE " . CORE::join(' AND ', @wheres);
    }
    
    if ($self->_orders->@*) {
        my @orders;
        for my $ord ($self->_orders->@*) {
            push @orders, "$ord->{column} $ord->{dir}";
        }
        $sql .= " ORDER BY " . CORE::join(', ', @orders);
    }
    
    if ($self->_limit) {
        $sql .= " LIMIT " . $self->_limit;
    }
    
    return $sql;
}

1;

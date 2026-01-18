package QueryBuilder;
use v5.36;
use Moo;

has _table       => (is => 'rw');
has _columns     => (is => 'rw', default => sub { [] });
has _joins       => (is => 'rw', default => sub { [] });
has _conditions  => (is => 'rw', default => sub { [] });
has _group_by    => (is => 'rw', default => sub { [] });
has _having      => (is => 'rw', default => sub { [] });
has _orders      => (is => 'rw', default => sub { [] });
has _limit       => (is => 'rw');
has _offset      => (is => 'rw');
has _bind_values => (is => 'rw', default => sub { [] });

sub from ($self, $table) {
    $self->_table($table);
    return $self;
}

sub select ($self, @columns) {
    push $self->_columns->@*, @columns;
    return $self;
}

sub join ($self, $table, $on_left, $on_right, $type = 'INNER') {
    push $self->_joins->@*, {
        type     => $type,
        table    => $table,
        on_left  => $on_left,
        on_right => $on_right,
    };
    return $self;
}

sub left_join ($self, $table, $on_left, $on_right) {
    return $self->join($table, $on_left, $on_right, 'LEFT');
}

sub where ($self, $column, $value) {
    push $self->_conditions->@*, { column => $column };
    push $self->_bind_values->@*, $value;
    return $self;
}

sub group_by ($self, @columns) {
    push $self->_group_by->@*, @columns;
    return $self;
}

sub having ($self, $column, $op, $value) {
    push $self->_having->@*, { column => $column, op => $op };
    push $self->_bind_values->@*, $value;
    return $self;
}

sub order_by ($self, $column, $dir = 'ASC') {
    push $self->_orders->@*, { column => $column, dir => $dir };
    return $self;
}

sub limit ($self, $count) {
    $self->_limit($count);
    return $self;
}

sub offset ($self, $count) {
    $self->_offset($count);
    return $self;
}

sub build ($self) {
    my @columns = $self->_columns->@*;
    my $cols = @columns ? CORE::join(', ', @columns) : '*';
    
    my $sql = "SELECT $cols FROM " . $self->_table;
    
    # JOIN
    for my $j ($self->_joins->@*) {
        $sql .= " $j->{type} JOIN $j->{table} ON $j->{on_left} = $j->{on_right}";
    }
    
    # WHERE
    if ($self->_conditions->@*) {
        my @wheres = map { "$_->{column} = ?" } $self->_conditions->@*;
        $sql .= " WHERE " . CORE::join(' AND ', @wheres);
    }
    
    # GROUP BY
    if ($self->_group_by->@*) {
        $sql .= " GROUP BY " . CORE::join(', ', $self->_group_by->@*);
    }
    
    # HAVING
    if ($self->_having->@*) {
        my @havings = map { "$_->{column} $_->{op} ?" } $self->_having->@*;
        $sql .= " HAVING " . CORE::join(' AND ', @havings);
    }
    
    # ORDER BY
    if ($self->_orders->@*) {
        my @orders = map { "$_->{column} $_->{dir}" } $self->_orders->@*;
        $sql .= " ORDER BY " . CORE::join(', ', @orders);
    }
    
    # LIMIT / OFFSET
    if ($self->_limit) {
        $sql .= " LIMIT " . $self->_limit;
        if ($self->_offset) {
            $sql .= " OFFSET " . $self->_offset;
        }
    }
    
    return $sql;
}

sub bind_values ($self) {
    return $self->_bind_values->@*;
}

1;

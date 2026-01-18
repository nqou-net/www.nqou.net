package QueryBuilder;
use v5.36;
use Moo;

has _table       => (is => 'rw');
has _columns     => (is => 'rw', default => sub { [] });
has _conditions  => (is => 'rw', default => sub { [] });
has _orders      => (is => 'rw', default => sub { [] });
has _limit       => (is => 'rw');
has _bind_values => (is => 'rw', default => sub { [] });

sub from ($self, $table) {
    $self->_table($table);
    return $self;
}

sub select ($self, @columns) {
    push $self->_columns->@*, @columns;
    return $self;
}

sub where ($self, $column, $value) {
    push $self->_conditions->@*, { column => $column };
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

sub build ($self) {
    my @columns = $self->_columns->@*;
    my $cols = @columns ? CORE::join(', ', @columns) : '*';
    
    my $sql = "SELECT $cols FROM " . $self->_table;
    
    if ($self->_conditions->@*) {
        my @wheres = map { "$_->{column} = ?" } $self->_conditions->@*;
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

sub bind_values ($self) {
    return $self->_bind_values->@*;
}

1;

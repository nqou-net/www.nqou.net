package SearchQueryBuilder;
use v5.36;

# This is the "Builder" class
# It encapsulates the construction logic of a complex SQL query.

sub new ($class) {
    return bless {
        base_sql => "SELECT p.id, p.name, p.price FROM products p",
        joins    => [],
        wheres   => [],
        binds    => [],
        order    => "ORDER BY p.id DESC",                             # Default
    }, $class;
}

sub with_category ($self, $category_id) {
    push $self->{joins}->@*,  "JOIN product_categories pc ON p.id = pc.product_id";
    push $self->{wheres}->@*, "pc.category_id = ?";
    push $self->{binds}->@*,  $category_id;
    return $self;
}

sub with_price_range ($self, $min, $max) {
    if (defined $min) {
        push $self->{wheres}->@*, "p.price >= ?";
        push $self->{binds}->@*,  $min;
    }
    if (defined $max) {
        push $self->{wheres}->@*, "p.price <= ?";
        push $self->{binds}->@*,  $max;
    }
    return $self;
}

sub in_stock ($self) {
    push $self->{joins}->@*,  "JOIN stocks s ON p.id = s.product_id";
    push $self->{wheres}->@*, "s.quantity > 0";
    return $self;
}

sub sort_by_price_asc ($self) {
    $self->{order} = "ORDER BY p.price ASC";
    return $self;
}

sub build ($self) {
    my $sql = $self->{base_sql};

    # Assemble parts
    if ($self->{joins}->@*) {
        $sql .= " " . join(" ", $self->{joins}->@*);
    }

    if ($self->{wheres}->@*) {
        $sql .= " WHERE " . join(" AND ", $self->{wheres}->@*);
    }

    $sql .= " " . $self->{order};

    # Return structure, or DBI statement handle in real world
    return ($sql, $self->{binds});
}

1;

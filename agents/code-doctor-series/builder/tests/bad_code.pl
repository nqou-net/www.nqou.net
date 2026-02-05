#!/usr/bin/env perl
use v5.36;
use Data::Dumper;

# Simulation of a "Bad" implementation: String Concatenation Hell

sub build_search_sql {
    my (%args) = @_;

    my $sql = "SELECT p.id, p.name, p.price FROM products p";
    my @binds;
    my @where;

    # Bad practice: Direct string manipulation and implicit dependencies
    if ($args{category_id}) {

        # Implicitly assumes no other joins yet
        $sql .= " JOIN product_categories pc ON p.id = pc.product_id";
        push @where, "pc.category_id = ?";
        push @binds, $args{category_id};
    }

    if ($args{min_price}) {
        push @where, "p.price >= ?";
        push @binds, $args{min_price};
    }

    if ($args{max_price}) {
        push @where, "p.price <= ?";
        push @binds, $args{max_price};
    }

    # Complex logic mixed with query building
    if (defined $args{in_stock} && $args{in_stock}) {
        $sql .= " JOIN stocks s ON p.id = s.product_id";
        push @where, "s.quantity > 0";
    }

    if (@where) {
        $sql .= " WHERE " . join(" AND ", @where);
    }

    # Ordering is hardcoded and fragile
    $sql .= " ORDER BY p.id DESC";

    return ($sql, \@binds);
}

# Example usage
my ($sql, $binds) = build_search_sql(
    category_id => 1,
    min_price   => 1000,
    in_stock    => 1,
);

say "--- Bad Code Result ---";
say "SQL: $sql";
say "Binds: " . join(", ", @$binds);

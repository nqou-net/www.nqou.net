#!/usr/bin/env perl
use v5.36;
use lib '.';
use SearchQueryBuilder;

# Simulation of "Good" implementation using Builder Pattern

# Client code is readable and declarative
my ($sql, $binds) = SearchQueryBuilder->new->with_category(1)->with_price_range(1000, undef)->in_stock->build;

say "--- Good Code Result ---";
say "SQL: $sql";
say "Binds: " . join(", ", @$binds);

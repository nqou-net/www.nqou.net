#!/usr/bin/env perl
use v5.36;
use lib '.';
use Test::More;
use SearchQueryBuilder;

subtest 'Basic Query Construction' => sub {
    my $builder = SearchQueryBuilder->new;
    my ($sql, $binds) = $builder->build;

    like $sql, qr/^SELECT/, 'Base SQL starts correctly';
    is scalar @$binds, 0, 'No binds initially';
};

subtest 'Complex Query Construction' => sub {
    my $builder = SearchQueryBuilder->new->with_category(5)->in_stock;

    my ($sql, $binds) = $builder->build;

    like $sql, qr/JOIN product_categories/,  'Category join included';
    like $sql, qr/JOIN stocks/,              'Stock join included';
    like $sql, qr/WHERE .*category_id = \?/, 'Category where clause included';
    like $sql, qr/AND .*quantity > 0/,       'Stock where clause included';
    is $binds->[0], 5, 'Bind value correct';
};

subtest 'Price Range' => sub {
    my ($sql, $binds) = SearchQueryBuilder->new->with_price_range(100, 200)->build;

    like $sql, qr/p\.price >= \?/, 'Min price condition';
    like $sql, qr/p\.price <= \?/, 'Max price condition';
    is $binds->[0], 100, 'Min bind';
    is $binds->[1], 200, 'Max bind';
};

done_testing;

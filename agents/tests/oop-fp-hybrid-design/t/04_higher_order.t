#!/usr/bin/env perl
use v5.36;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

# 第4回: 高階関数（map/grep/reduce）

subtest '第4回 - 高階関数で宣言的に書く' => sub {
    use_ok('Ch04_HigherOrderFunction');
    Ch04_HigherOrderFunction->import(
        qw(
            filter_available_items
            calculate_totals_by_category
        )
    );

    subtest 'filter_available_items で在庫ありをフィルタ' => sub {
        my @items = ({name => 'A', in_stock => 1}, {name => 'B', in_stock => 0}, {name => 'C', in_stock => 1},);

        my $available = filter_available_items(\@items);
        is(scalar(@$available),     2,   '在庫ありが2件');
        is($available->[0]->{name}, 'A', '1件目はA');
        is($available->[1]->{name}, 'C', '2件目はC');
    };

    subtest 'calculate_totals_by_category でカテゴリ別集計' => sub {
        my @items = (
            {name => 'Book1', category => 'books',      price => 1000, quantity => 2},
            {name => 'Book2', category => 'books',      price => 1500, quantity => 1},
            {name => 'Pen',   category => 'stationery', price => 200,  quantity => 5},
        );

        my $totals = calculate_totals_by_category(\@items);
        is($totals->{books},      3500, 'books: 2000 + 1500 = 3500');
        is($totals->{stationery}, 1000, 'stationery: 200 * 5 = 1000');
    };

    subtest 'カテゴリなしは other に集約' => sub {
        my @items = ({name => 'Unknown', price => 500, quantity => 2},);

        my $totals = calculate_totals_by_category(\@items);
        is($totals->{other}, 1000, 'other: 500 * 2 = 1000');
    };
};

done_testing;

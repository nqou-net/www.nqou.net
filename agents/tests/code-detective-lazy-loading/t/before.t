use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use Test::More;

do './agents/tests/code-detective-lazy-loading/before/lib.pl' or die $@ || $!;

my $make_store = sub {
    DataStore->reset_counter;
    my $store = DataStore->new;
    $store->register("dept:1",        { name => 'Engineering' });
    $store->register("attendance:1",  [{ date => '2026-01-01', hours => 8 }]);
    $store->register("evaluations:1", [{ score => 'A', period => '2025-H2' }]);
    DataStore->reset_counter;  # register のカウントをリセット
    return $store;
};

subtest 'Before: 正常系 — 全データが取得できる' => sub {
    my $store = $make_store->();
    my $emp   = Employee->new(id => 1, name => 'Alice', store => $store);

    is($emp->name, 'Alice', '名前が正しい');
    is($emp->department->{name}, 'Engineering', '部署が正しい');
    is($emp->attendance->[0]{hours}, 8, '勤怠が正しい');
    is($emp->evaluations->[0]{score}, 'A', '評価が正しい');
};

subtest 'Before: 問題点 — 生成時に3回のクエリが即座に発生する' => sub {
    my $store = $make_store->();

    Employee->new(id => 1, name => 'Alice', store => $store);

    is($DataStore::TOTAL_QUERIES, 3, 'new するだけで3回のクエリ');
};

subtest 'Before: 問題点 — 名前だけ使っても3回のクエリが発生する' => sub {
    my $store = $make_store->();
    my $emp   = Employee->new(id => 1, name => 'Alice', store => $store);

    # 名前しか使わない
    my $name = $emp->name;

    is($DataStore::TOTAL_QUERIES, 3, '名前だけ使っても3回のクエリ');
};

subtest 'Before: 問題点 — 100人で300回のクエリが発生する' => sub {
    my $store = $make_store->();

    for my $i (1..100) {
        Employee->new(id => $i, name => "Employee$i", store => $store);
    }

    is($DataStore::TOTAL_QUERIES, 300, '100人で300回のクエリ');
};

done_testing;

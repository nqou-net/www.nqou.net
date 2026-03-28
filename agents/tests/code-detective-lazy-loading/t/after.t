use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use Test::More;

do './agents/tests/code-detective-lazy-loading/after/lib.pl' or die $@ || $!;

my $make_store = sub {
    DataStore->reset_counter;
    my $store = DataStore->new;
    $store->register("dept:1",        { name => 'Engineering' });
    $store->register("attendance:1",  [{ date => '2026-01-01', hours => 8 }]);
    $store->register("evaluations:1", [{ score => 'A', period => '2025-H2' }]);
    DataStore->reset_counter;
    return $store;
};

subtest 'After: 正常系 — アクセスすれば全データが取得できる' => sub {
    my $store = $make_store->();
    my $emp   = Employee->new(id => 1, name => 'Alice', store => $store);

    is($emp->name, 'Alice', '名前が正しい');
    is($emp->department->{name}, 'Engineering', '部署が正しい');
    is($emp->attendance->[0]{hours}, 8, '勤怠が正しい');
    is($emp->evaluations->[0]{score}, 'A', '評価が正しい');
    is($DataStore::TOTAL_QUERIES, 3, '全属性アクセスで3回のクエリ');
};

subtest 'After: 生成時にはクエリが発生しない' => sub {
    my $store = $make_store->();

    Employee->new(id => 1, name => 'Alice', store => $store);

    is($DataStore::TOTAL_QUERIES, 0, 'new してもクエリはゼロ');
};

subtest 'After: 名前だけ使えばクエリはゼロ' => sub {
    my $store = $make_store->();
    my $emp   = Employee->new(id => 1, name => 'Alice', store => $store);

    my $name = $emp->name;

    is($name, 'Alice', '名前が正しい');
    is($DataStore::TOTAL_QUERIES, 0, '名前だけならクエリはゼロ');
};

subtest 'After: department だけアクセスすれば1回のクエリ' => sub {
    my $store = $make_store->();
    my $emp   = Employee->new(id => 1, name => 'Alice', store => $store);

    my $dept = $emp->department;

    is($dept->{name}, 'Engineering', '部署が正しい');
    is($DataStore::TOTAL_QUERIES, 1, '部署だけなら1回のクエリ');
};

subtest 'After: 同じ属性への2回目のアクセスではクエリが発生しない' => sub {
    my $store = $make_store->();
    my $emp   = Employee->new(id => 1, name => 'Alice', store => $store);

    $emp->department;
    is($DataStore::TOTAL_QUERIES, 1, '1回目のアクセスで1クエリ');

    $emp->department;
    is($DataStore::TOTAL_QUERIES, 1, '2回目のアクセスでクエリ増えない');
};

subtest 'After: 100人の一覧表示（名前のみ）でクエリはゼロ' => sub {
    my $store = $make_store->();

    my @employees;
    for my $i (1..100) {
        push @employees, Employee->new(
            id => $i, name => "Employee$i", store => $store,
        );
    }

    # 一覧表示：名前だけ使う
    my @names = map { $_->name } @employees;

    is(scalar @names, 100, '100人の名前を取得');
    is($DataStore::TOTAL_QUERIES, 0, '100人でもクエリはゼロ');
};

subtest 'After: 必要な人だけ詳細を読み込める' => sub {
    my $store = $make_store->();

    my @employees;
    for my $i (1..100) {
        push @employees, Employee->new(
            id => $i, name => "Employee$i", store => $store,
        );
    }

    # 1人だけ部署を確認
    $employees[0]->department;

    is($DataStore::TOTAL_QUERIES, 1, '1人だけ詳細を見ても1クエリ');
};

done_testing;

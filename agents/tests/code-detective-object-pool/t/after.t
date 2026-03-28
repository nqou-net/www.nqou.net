use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use Test::More;

do './agents/tests/code-detective-object-pool/after/lib.pl' or die $@ || $!;

my $make_pool = sub {
    DatabaseConnection->reset_counter;
    return ConnectionPool->new(
        max_size => 3,
        factory  => sub { DatabaseConnection->new->connect },
    );
};

my @records = map { { id => $_ } } 1..10;

subtest 'After: ConnectionPool — acquire で新規オブジェクトが生成される' => sub {
    my $pool = $make_pool->();
    my $conn = $pool->acquire;

    isa_ok($conn, 'DatabaseConnection');
    ok($conn->is_connected, '接続済み');
    is($pool->size, 1, 'プールサイズが1');
    is($pool->in_use_count, 1, '使用中が1');
    is($pool->available_count, 0, '利用可能が0');
};

subtest 'After: ConnectionPool — release で返却されたオブジェクトが再利用される' => sub {
    my $pool = $make_pool->();

    my $conn1 = $pool->acquire;
    $pool->release($conn1);

    is($pool->available_count, 1, '返却後に利用可能が1');
    is($pool->in_use_count, 0, '使用中が0');

    my $conn2 = $pool->acquire;
    is($conn1, $conn2, '同一オブジェクトが再利用される');
    is($DatabaseConnection::TOTAL_CREATED, 1, '接続生成は1回だけ');
};

subtest 'After: ConnectionPool — max_size を超えると例外' => sub {
    my $pool = $make_pool->();

    $pool->acquire for 1..3;

    eval { $pool->acquire };
    like($@, qr/Pool exhausted/, 'max_size超過で例外');
    is($pool->in_use_count, 3, '使用中が3');
};

subtest 'After: ConnectionPool — 使用中でないオブジェクトの release は例外' => sub {
    my $pool = $make_pool->();
    my $outsider = DatabaseConnection->new->connect;

    eval { $pool->release($outsider) };
    like($@, qr/Object not found/, 'プール外オブジェクトの返却で例外');
};

subtest 'After: ConnectionPool — acquire と release の繰り返しで再利用される' => sub {
    my $pool = $make_pool->();

    for my $i (1..10) {
        my $conn = $pool->acquire;
        $conn->execute('SELECT ?', $i);
        $pool->release($conn);
    }

    is($DatabaseConnection::TOTAL_CREATED, 1, '10回の利用で接続生成は1回だけ');
    is($pool->size, 1, 'プールサイズは1のまま');
};

subtest 'After: BatchProcessor — 全レコードが正しく処理される' => sub {
    my $pool = $make_pool->();
    my $processor = BatchProcessor->new(pool => $pool);
    my $results   = $processor->process_records(\@records);

    is(scalar @$results, 10, '10件のレコードが処理される');
    is($results->[0]{status}, 'ok', 'ステータスがok');
    is($results->[0]{query}, 'SELECT * FROM sales WHERE id = ?', 'クエリが正しい');
    is_deeply($results->[0]{params}, [1], 'パラメータが正しい');
};

subtest 'After: BatchProcessor — 接続が再利用され生成回数が激減する' => sub {
    my $pool = $make_pool->();
    my $processor = BatchProcessor->new(pool => $pool);
    $processor->process_records(\@records);

    is($DatabaseConnection::TOTAL_CREATED, 1, '10件でも接続生成は1回');
};

subtest 'After: 大量レコードでも接続生成は max_size 以下' => sub {
    my $pool = $make_pool->();
    my $processor = BatchProcessor->new(pool => $pool);
    my @large = map { { id => $_ } } 1..100;
    $processor->process_records(\@large);

    cmp_ok($DatabaseConnection::TOTAL_CREATED, '<=', 3, '100件でも接続生成は3以下');
};

done_testing;

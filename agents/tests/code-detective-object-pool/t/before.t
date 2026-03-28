use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use Test::More;

do './agents/tests/code-detective-object-pool/before/lib.pl' or die $@ || $!;

my @records = map { { id => $_ } } 1..10;

subtest 'Before: 正常系 — 全レコードが処理される' => sub {
    DatabaseConnection->reset_counter;
    my $processor = BatchProcessor->new;
    my $results   = $processor->process_records(\@records);

    is(scalar @$results, 10, '10件のレコードが処理される');
    is($results->[0]{status}, 'ok', '各結果のステータスがok');
    is($results->[0]{query}, 'SELECT * FROM sales WHERE id = ?', 'クエリが正しい');
    is_deeply($results->[0]{params}, [1], 'パラメータが正しい');
};

subtest 'Before: 問題点 — レコード数と同じ回数の接続が生成される' => sub {
    DatabaseConnection->reset_counter;
    my $processor = BatchProcessor->new;
    $processor->process_records(\@records);

    is($DatabaseConnection::TOTAL_CREATED, 10, '10件で10回の接続生成');
};

subtest 'Before: 問題点 — 大量レコードで大量の接続が生成される' => sub {
    DatabaseConnection->reset_counter;
    my @large = map { { id => $_ } } 1..100;
    my $processor = BatchProcessor->new;
    $processor->process_records(\@large);

    is($DatabaseConnection::TOTAL_CREATED, 100, '100件で100回の接続生成');
};

subtest 'Before: 問題点 — 接続は使い捨てで再利用されない' => sub {
    my $processor = BatchProcessor->new;
    # 処理中に接続を保持する仕組みがない
    ok(!$processor->can('pool'), 'プール機能が存在しない');
};

done_testing;

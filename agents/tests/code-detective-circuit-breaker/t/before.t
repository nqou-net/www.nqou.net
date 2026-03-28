use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use Test::More;

do './agents/tests/code-detective-circuit-breaker/before/lib.pl' or die $@ || $!;

subtest 'Before: 正常系 — APIが正常なら結果を返す' => sub {
    ExternalService->reset_counter;
    my $service = ExternalService->new(is_healthy => 1);
    my $client  = ExternalApiClient->new(service => $service);

    my $result = $client->call({ id => 1 });

    is($result->{status}, 'ok', 'ステータスがok');
    is_deeply($result->{data}, { id => 1 }, 'データが正しい');
    is($ExternalService::TOTAL_CALLS, 1, '1回の呼び出しで成功');
};

subtest 'Before: 問題点 — API障害時に max_retries 回リトライする' => sub {
    ExternalService->reset_counter;
    my $service = ExternalService->new(is_healthy => 0);
    my $client  = ExternalApiClient->new(service => $service, max_retries => 3);

    eval { $client->call({ id => 1 }) };

    like($@, qr/API call failed after 3 attempts/, 'リトライ後に例外');
    is($ExternalService::TOTAL_CALLS, 3, '3回リトライが発生');
};

subtest 'Before: 問題点 — 複数リクエストで呼び出し数が爆発する' => sub {
    ExternalService->reset_counter;
    my $service = ExternalService->new(is_healthy => 0);
    my $client  = ExternalApiClient->new(service => $service, max_retries => 3);

    for my $i (1..10) {
        eval { $client->call({ id => $i }) };
    }

    is($ExternalService::TOTAL_CALLS, 30, '10リクエスト×3リトライ=30回の呼び出し');
};

subtest 'Before: 問題点 — 障害中もリトライを止める仕組みがない' => sub {
    my $client = ExternalApiClient->new(
        service => ExternalService->new(is_healthy => 0),
    );

    ok(!$client->can('breaker'), 'ブレーカー機能が存在しない');
};

done_testing;

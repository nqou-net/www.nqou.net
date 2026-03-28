use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use Test::More;

do './agents/tests/code-detective-circuit-breaker/after/lib.pl' or die $@ || $!;

my $fake_time = 0;

my $make_breaker = sub (%opts) {
    $fake_time = 0;
    return CircuitBreaker->new(
        failure_threshold => $opts{threshold} // 3,
        recovery_timeout  => $opts{timeout}   // 10,
        _now_func         => sub { $fake_time },
    );
};

subtest 'After: 正常系 — Closed 状態でリクエストが通る' => sub {
    my $breaker = $make_breaker->();
    my $result  = $breaker->call(sub { { status => 'ok' } });

    is($result->{status}, 'ok', 'リクエストが成功');
    is($breaker->state, 'closed', '状態は closed');
    is($breaker->failure_count, 0, '失敗カウントは0');
};

subtest 'After: 失敗が閾値未満なら Closed のまま' => sub {
    my $breaker = $make_breaker->(threshold => 3);

    for my $i (1..2) {
        eval { $breaker->call(sub { die "fail" }) };
    }

    is($breaker->state, 'closed', '2回失敗でもまだ closed');
    is($breaker->failure_count, 2, '失敗カウントが2');
};

subtest 'After: 失敗が閾値に達すると Open になる' => sub {
    my $breaker = $make_breaker->(threshold => 3);

    for my $i (1..3) {
        eval { $breaker->call(sub { die "fail" }) };
    }

    is($breaker->state, 'open', '3回失敗で open');
    is($breaker->failure_count, 3, '失敗カウントが3');
};

subtest 'After: Open 状態ではリクエストが即座に拒否される' => sub {
    ExternalService->reset_counter;
    my $service = ExternalService->new(is_healthy => 0);
    my $breaker = $make_breaker->(threshold => 3);

    # 閾値まで失敗させて Open にする
    for my $i (1..3) {
        eval { $breaker->call(sub { $service->request({}) }) };
    }
    is($ExternalService::TOTAL_CALLS, 3, 'Open になるまで3回呼び出し');

    # Open 状態で追加リクエスト
    ExternalService->reset_counter;
    for my $i (1..10) {
        eval { $breaker->call(sub { $service->request({}) }) };
    }

    is($ExternalService::TOTAL_CALLS, 0, 'Open 中は外部APIを一切呼ばない');
    like($@, qr/Circuit is open/, 'Open 中はブレーカー例外');
};

subtest 'After: recovery_timeout 経過後に Half-Open になる' => sub {
    my $breaker = $make_breaker->(threshold => 3, timeout => 10);

    for my $i (1..3) {
        eval { $breaker->call(sub { die "fail" }) };
    }
    is($breaker->state, 'open', 'Open になった');

    # 時間を進める
    $fake_time = 10;

    # Half-Open で成功すれば Closed に戻る
    my $result = $breaker->call(sub { { status => 'recovered' } });

    is($result->{status}, 'recovered', 'リクエストが成功');
    is($breaker->state, 'closed', 'Closed に復帰');
    is($breaker->failure_count, 0, '失敗カウントがリセット');
};

subtest 'After: Half-Open で失敗すると再び Open に戻る' => sub {
    my $breaker = $make_breaker->(threshold => 3, timeout => 10);

    for my $i (1..3) {
        eval { $breaker->call(sub { die "fail" }) };
    }
    is($breaker->state, 'open', 'Open になった');

    # 時間を進めて Half-Open に
    $fake_time = 10;
    eval { $breaker->call(sub { die "still failing" }) };

    is($breaker->state, 'open', '失敗したので再び Open');
};

subtest 'After: 成功すると失敗カウントがリセットされる' => sub {
    my $breaker = $make_breaker->(threshold => 3);

    # 2回失敗
    for my $i (1..2) {
        eval { $breaker->call(sub { die "fail" }) };
    }
    is($breaker->failure_count, 2, '失敗カウントが2');

    # 1回成功
    $breaker->call(sub { { status => 'ok' } });

    is($breaker->failure_count, 0, '成功で失敗カウントがリセット');
    is($breaker->state, 'closed', '状態は closed');
};

subtest 'After: ExternalApiClient が CircuitBreaker 経由で呼び出す' => sub {
    ExternalService->reset_counter;
    my $service = ExternalService->new(is_healthy => 1);
    my $breaker = $make_breaker->(threshold => 3);
    my $client  = ExternalApiClient->new(service => $service, breaker => $breaker);

    my $result = $client->call({ id => 42 });

    is($result->{status}, 'ok', 'リクエスト成功');
    is_deeply($result->{data}, { id => 42 }, 'データが正しい');
};

subtest 'After: 障害時に CircuitBreaker が呼び出しを遮断する' => sub {
    ExternalService->reset_counter;
    my $service = ExternalService->new(is_healthy => 0);
    my $breaker = $make_breaker->(threshold => 3);
    my $client  = ExternalApiClient->new(service => $service, breaker => $breaker);

    # 閾値まで失敗させる
    for my $i (1..3) {
        eval { $client->call({ id => $i }) };
    }
    is($ExternalService::TOTAL_CALLS, 3, '3回で遮断');

    # 遮断後はAPIを呼ばない
    ExternalService->reset_counter;
    for my $i (1..10) {
        eval { $client->call({ id => $i }) };
    }
    is($ExternalService::TOTAL_CALLS, 0, '遮断後は外部APIを呼ばない');
};

done_testing;

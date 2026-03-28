use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use Test::More;

do './agents/tests/code-detective-dependency-injection/after/lib.pl' or die $@ || $!;

subtest 'After: 正常系 — DIで打刻記録が作成される' => sub {
    my $db       = InMemoryDB->new;
    my $notifier = MockNotifier->new;
    my $svc      = AttendanceService->new(db => $db, notifier => $notifier);

    my $result = $svc->record_clock_in('EMP-001');

    is($result->{employee_id}, 'EMP-001', '従業員IDが正しい');
    ok($result->{timestamp}, 'タイムスタンプが設定されている');
    is($db->count, 1, 'DBにレコードが1件');
    is($notifier->sent_count, 1, '通知が1件送信された');
};

subtest 'After: テスト間でDB状態が干渉しない' => sub {
    my $db1       = InMemoryDB->new;
    my $notifier1 = MockNotifier->new;
    my $svc1      = AttendanceService->new(db => $db1, notifier => $notifier1);
    $svc1->record_clock_in('EMP-A');

    my $db2       = InMemoryDB->new;
    my $notifier2 = MockNotifier->new;
    my $svc2      = AttendanceService->new(db => $db2, notifier => $notifier2);
    $svc2->record_clock_in('EMP-B');

    is($db1->count, 1, 'テスト1のDBは1件のまま');
    is($db2->count, 1, 'テスト2のDBも1件のみ');
    isnt($db1, $db2, '異なるDBインスタンス（テスト間干渉なし）');
};

subtest 'After: モック差し替えが容易' => sub {
    my $mock_db       = InMemoryDB->new;
    my $mock_notifier = MockNotifier->new;
    my $svc = AttendanceService->new(db => $mock_db, notifier => $mock_notifier);

    $svc->record_clock_in('EMP-X');

    is($mock_db->count, 1, 'モックDBにレコードが保存された');
    is($mock_notifier->sent_count, 1, 'モック通知に送信が記録された');
    like(
        $mock_notifier->sent->[0]{subject},
        qr/Clock-in: Employee EMP-X/,
        '送信内容を検証できる',
    );
};

subtest 'After: 依存がコンストラクタで明示されている' => sub {
    my $svc = AttendanceService->new(db => InMemoryDB->new, notifier => MockNotifier->new);
    ok($svc->can('db'),       'dbアクセサが存在する（依存が明示的）');
    ok($svc->can('notifier'), 'notifierアクセサが存在する（依存が明示的）');
};

subtest 'After: 依存が未指定ならコンストラクタでエラー' => sub {
    eval { AttendanceService->new };
    like($@, qr/required/, '必須属性が未指定でエラー');
};

subtest 'After: 複数回の打刻が正しく記録される' => sub {
    my $db       = InMemoryDB->new;
    my $notifier = MockNotifier->new;
    my $svc      = AttendanceService->new(db => $db, notifier => $notifier);

    $svc->record_clock_in('EMP-001');
    $svc->record_clock_in('EMP-002');
    $svc->record_clock_in('EMP-003');

    is($db->count, 3, 'DBに3件のレコード');
    is($notifier->sent_count, 3, '通知が3件送信された');
};

done_testing;

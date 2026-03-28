use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use Test::More;

do './agents/tests/code-detective-dependency-injection/before/lib.pl' or die $@ || $!;

subtest 'Before: 正常系 — 打刻記録が作成される' => sub {
    my $svc    = AttendanceService->new;
    my $result = $svc->record_clock_in('EMP-001');

    is($result->{employee_id}, 'EMP-001', '従業員IDが正しい');
    ok($result->{timestamp}, 'タイムスタンプが設定されている');
};

subtest 'Before: 問題点 — メソッド内部で毎回新しいインスタンスが生成される' => sub {
    my $svc = AttendanceService->new;

    # record_clock_in を2回呼ぶと、毎回新しい Database と NotificationService が作られる
    # → 前の呼び出しで挿入したレコードを検証する手段がない
    $svc->record_clock_in('EMP-001');
    $svc->record_clock_in('EMP-002');

    # 外部から DB や通知サービスの状態を確認する方法がない
    ok(!$svc->can('db'),       'dbアクセサが存在しない（依存が隠蔽）');
    ok(!$svc->can('notifier'), 'notifierアクセサが存在しない（依存が隠蔽）');
};

subtest 'Before: 問題点 — 接続先がハードコードされている' => sub {
    # Database->new(dsn => 'dbi:Pg:dbname=attendance_prod') がメソッド内に直書き
    # テスト環境でも本番DSNが使われてしまう
    # ここではコードの構造的問題を示すだけ
    my $svc = AttendanceService->new;
    ok(1, 'テスト環境でも本番DSNに接続してしまう構造');
};

subtest 'Before: 問題点 — コンストラクタから依存関係が読み取れない' => sub {
    # AttendanceService->new に引数がないため、何に依存しているか不明
    my $svc = AttendanceService->new;
    is(ref($svc), 'AttendanceService', 'インスタンスは作成できる');
    ok(!$svc->can('db'),       'dbへの依存がコンストラクタに現れない');
    ok(!$svc->can('notifier'), 'notifierへの依存がコンストラクタに現れない');
};

done_testing;
